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
    schedule.start_at   = event.start.date_time.change(sec: 0, usec: 0)
    schedule.summary    = event.summary
    schedule.schedule_reminders = build_reminders(event:, schedule:)

    ActiveRecord::Base.transaction do
      schedule.save! if schedule.changed?
      setting_notification(schedule:) if schedule.saved_changes?
    end
  end

  def build_reminders(event:, schedule:)
    schedule.schedule_reminders.destroy_all if changed_reminder?(event:, schedule:)
    return [] unless setting_reminder?(event:)

    event.reminders.overrides.map do |override|
      schedule.schedule_reminders.find_or_initialize_by(
        reminder_method: override.reminder_method,
        minutes: override.minutes
      )
    end
  end

  def setting_reminder?(event:)
    event.reminders&.overrides.present?
  end

  def changed_reminder?(event:, schedule:)
    return false unless event.reminders&.overrides
    event.reminders.overrides.map(&:minutes).sort !=
      schedule.schedule_reminders.map(&:minutes).sort
  end

  def setting_notification(schedule:)
    clean_jobs(schedule:)
    return if schedule.schedule_reminders.blank?

    schedule.schedule_reminders.each do |reminder|
      wait_until = schedule.start_at - reminder.minutes.minutes
      next unless wait_until > Time.current
      job = NotifySchedulesJob.set(wait_until:).perform_later(schedule_reminder_id: reminder.id)
      reminder.update!(job_id: job.job_id)
    end
  end

  def clean_jobs(schedule:)
    job_ids = schedule.schedule_reminders.filter_map(&:job_id)
    return if job_ids.blank?
    SolidQueue::Job.where(active_job_id: job_ids).destroy_all
    schedule.schedule_reminders.update_all(job_id: nil)
  end
end
