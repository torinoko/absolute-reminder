# frozen_string_literal: true

class NotifySchedulesJob < ApplicationJob
  queue_as :default

  def perform(schedule_reminder_id:)
    schedule_reminder = ScheduleReminder.find(schedule_reminder_id)
    schedule = schedule_reminder.schedule
    start_at = schedule.start_at.strftime('%H:%M')
    text = "#{start_at}\n#{schedule.summary}\nまであと#{time(schedule_reminder:)}だよ 🕊️"
    process_notification(schedule:, text:)
  end

  private

  def time(schedule_reminder:)
    hours = schedule_reminder.minutes / 60
    minutes = schedule_reminder.minutes % 60
    hours_text = "#{hours}時間" if hours.positive?
    minutes_text = "#{minutes}分" if minutes.positive?
    "#{hours_text}#{minutes_text}"
  end

  def process_notification(schedule:, text:)
    user = schedule.user

    begin
      user.notification_targets.each do |platform, uid|
        case platform
        when :line    then Line::SendMessageService.call(uid:, text:)
        when :discord then Discord::SendMessageService.call(uid:, text:)
        end
      end
    rescue StandardError => e
      Rails.logger.error "Notification send message error (Schedule ID: #{schedule.id}): #{e.class} - #{e.message}"
    end
  end
end
