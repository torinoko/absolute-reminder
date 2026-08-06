class ScheduleSync
  attr_reader :user

  def self.call(user)
    new(user).call
  end

  def initialize(user)
    @user = user
  end

  def call
    events = Google::Calendar.call(user)
    events.each { |event| sync(event) }
  end

  private

  def sync(event)
    schedule = user.schedules.find_or_initialize_by(google_event_id: event.id)
    previous_job_ids = schedule.schedule_reminders.filter_map(&:job_id)

    ActiveRecord::Base.transaction do
      schedule.assign_attributes(
        start_at: event.start.date_time.change(sec: 0, usec: 0),
        summary: event.summary
      )
      schedule.save!

      reminders_changed = sync_reminders!(event:, schedule:)
      if schedule.saved_changes? || reminders_changed
        setting_notification(schedule:, previous_job_ids:)
      end
    end
  end

  def sync_reminders!(event:, schedule:)
    overrides = event.reminders&.overrides.to_a
    current = schedule.schedule_reminders.map do |reminder|
      [reminder.reminder_method.to_s, reminder.minutes]
    end
    desired = overrides.map do |override|
      [override.reminder_method.to_s, override.minutes]
    end

    return false if current.sort == desired.sort

    schedule.schedule_reminders.destroy_all
    overrides.each do |override|
      schedule.schedule_reminders.create!(
        reminder_method: override.reminder_method,
        minutes: override.minutes
      )
    end

    true
  end

  def setting_notification(schedule:, previous_job_ids:)
    clean_jobs(job_ids: previous_job_ids)
    return if schedule.schedule_reminders.blank?

    schedule.schedule_reminders.each do |reminder|
      wait_until = schedule.start_at - reminder.minutes.minutes
      next unless wait_until > Time.current
      job = NotifySchedulesJob.set(wait_until:).perform_later(schedule_reminder_id: reminder.id)
      reminder.update!(job_id: job.job_id)
    end
  end

  def clean_jobs(job_ids:)
    return if job_ids.blank?
    SolidQueue::Job.where(active_job_id: job_ids).destroy_all
  end
end
