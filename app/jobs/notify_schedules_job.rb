# frozen_string_literal: true

class NotifySchedulesJob < ApplicationJob
  queue_as :default

  def perform(schedule_id:)
    schedule = Schedule.find(schedule_id)
    process_notification(schedule)
  end

  private

  def process_notification(schedule)
    user = schedule.user
    start_at = schedule.start_at.strftime('%H:%M')
    text = "#{start_at}: #{schedule.summary} 🕊️"

    begin
      uid = user.profile_for(:line)&.uid
      if uid
        Line::SendMessageService.call(uid:, text:)
      end

      uid = user.profile_for(:discord)&.uid
      if uid
        Discord::SendMessageService.call(uid:, text:)
      end

      schedule.update!(notified: true)
    rescue StandardError => e
      Rails.logger.error "Notification send message error (Schedule ID: #{schedule.id}): #{e.class} - #{e.message}"
    end
  end
end