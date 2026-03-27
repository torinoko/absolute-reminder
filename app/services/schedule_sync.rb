# frozen_string_literal: true

class ScheduleSync
  class << self
    def call(user)
      events = Google::Calendar.call(user)

      events.each do |event|
        schedule = user.schedules.find_or_initialize_by(google_event_id: event.id)
        ActiveRecord::Base.transaction do
          schedule.update!(
            start_at: event.start.date_time.change(sec: 0, usec: 0),
            summary: event.summary,
            schedule_reminders: schedule_reminders(event:, schedule:)
          )
        end
        settings_schedule_notification(schedule:)
      end
    end

    private

    def schedule_reminders(event:, schedule:)
      reminders = []
      if reminder_settings?(event:)
        event.reminders.overrides.each do |override|
          method = override.reminder_method
          minutes = override.minutes
          reminders << schedule.schedule_reminders.find_or_initialize_by(method:, minutes:)
        end
      end
      reminders
    end

    private

    def reminder_settings?(event:)
      event.reminders && event.reminders.overrides.present?
    end

    def change_start_at?(event:, schedule:)
      event.start.date_time.change(sec: 0, usec: 0) != schedule.start_at_was
    end

    def settings_schedule_notification(schedule:)
      cleaning_job(schedule:)
      return if schedule.schedule_reminders&.blank?

      recent_reminder = schedule.schedule_reminders.order(minutes: :asc).last
      last_minute_reminder = schedule.schedule_reminders.order(minutes: :asc).first
      recent_time = schedule.start_at - recent_reminder.minutes
      last_minute_time = schedule.start_at - last_minute_reminder.minutes

      if recent_time > Time.current
        job = NotifySchedulesJob.set(wait_until: recent_time).perform_later(schedule_reminder_id: recent_reminder.id)
        recent_reminder.update!(job_id: job.job_id)
      end
      if last_minute_time > Time.current && recent_reminder.id != last_minute_reminder.id
        job = NotifySchedulesJob.set(wait_until: last_minute_time).perform_later(schedule_reminder_id: last_minute_reminder.id)
        last_minute_reminder.update!(job_id: job.job_id)
      end
    end

    def cleaning_job(schedule:)
      job_ids = schedule.schedule_reminders&.filter_map(&:job_id)

      if job_ids.present?
        SolidQueue::Job.where(active_job_id: job_ids).destroy_all
        schedule.schedule_reminders.update_all(job_id: nil)
      end
    end
  end
end
