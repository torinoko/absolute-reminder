# frozen_string_literal: true

class ScheduleSync
  class << self
    def call(user)
      events = Google::Calendar.call(user)

      events.each do |event|
        schedule = user.schedules.find_or_initialize_by(google_event_id: event.id)
        schedule.start_at = event.start.date_time.change(sec: 0, usec: 0)

        if changed_start_at?(event:, schedule:)
          schedule.summary = event.summary
          schedule.schedule_reminders = initialize_schedule_reminders(event:, schedule:)
          ActiveRecord::Base.transaction do
            schedule.save!
            setting_notification(schedule:)
          end
        end
      end
    end

    private

    def initialize_schedule_reminders(event:, schedule:)
      reminders = []
      if setting_reminder?(event:)
        event.reminders.overrides.each do |override|
          method = override.reminder_method
          minutes = override.minutes
          reminders << schedule.schedule_reminders.find_or_initialize_by(method:, minutes:)
        end
      end
      reminders
    end

    def setting_reminder?(event:)
      event.reminders && event.reminders.overrides.present?
    end

    def changed_start_at?(event:, schedule:)
      event.start.date_time.change(sec: 0, usec: 0) != schedule.start_at_was
    end

    def setting_notification(schedule:)
      cleaning_job(schedule:)
      return if schedule.schedule_reminders&.blank?

      schedule.schedule_reminders.each do |reminder|
        wait_until = schedule.start_at - reminder.minutes.minutes
        job = NotifySchedulesJob.set(wait_until:).perform_later(schedule_reminder_id: reminder.id)
        reminder.update!(job_id: job.job_id)
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
