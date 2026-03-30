# frozen_string_literal: true

class ScheduleSync
  attr_reader :user, :event, :schedule

  def self.call(user)
    new(user).schedules_from_google_calendar
  end

  def initialize(user)
    @user = user
  end

  def schedules_from_google_calendar
    events = Google::Calendar.call(user)

    events.each do |event|
      @event = event
      @schedule = user.schedules.find_or_initialize_by(google_event_id: event.id)
      schedule.start_at = event.start.date_time.change(sec: 0, usec: 0)
      schedule.summary = event.summary
      schedule.schedule_reminders = initialize_schedule_reminders
      schedule.save!
      setting_notification
    end
  end

  private

  def initialize_schedule_reminders
    reminders = []
    if changed_reminder?
      schedule.schedule_reminders.destroy_all
    end

    if setting_reminder?
      event.reminders.overrides.each do |override|
        method = override.reminder_method
        minutes = override.minutes
        reminders << schedule.schedule_reminders.find_or_initialize_by(method:, minutes:)
      end
    end

    reminders
  end

  def setting_reminder?
    event.reminders && event.reminders.overrides.present?
  end

  def changed_reminder?
    event.reminders.overrides.pluck(:minutes).sort != schedule.schedule_reminders.pluck(:minutes).sort
  end

  def setting_notification
    cleaning_job
    return if schedule.schedule_reminders&.blank?

    schedule.schedule_reminders.each do |reminder|
      wait_until = schedule.start_at - reminder.minutes.minutes
      job = NotifySchedulesJob.set(wait_until:).perform_later(schedule_reminder_id: reminder.id)
      reminder.update!(job_id: job.job_id)
    end
  end

  def cleaning_job
    job_ids = schedule.schedule_reminders&.filter_map(&:job_id)

    if job_ids.present?
      SolidQueue::Job.where(active_job_id: job_ids).destroy_all
      schedule.schedule_reminders.update_all(job_id: nil)
    end
  end
end
