# frozen_string_literal: true

class NotificationDeliveryError < StandardError; end

class NotifySchedulesJob < ApplicationJob
  queue_as :default
  retry_on NotificationDeliveryError, wait: :exponentially_longer, attempts: 5

  def perform(schedule_reminder_id:)
    schedule_reminder = ScheduleReminder.find(schedule_reminder_id)
    schedule = schedule_reminder.schedule
    start_text = "#{schedule.start_at.strftime('%H:%M')}からはじまる"
    text = "#{start_text}\n#{schedule.summary}\nまであと#{time_text(schedule_reminder:)}だよ 🕊️"
    process_notification(schedule_reminder:, schedule:, text:)
  end

  private

  def time_text(schedule_reminder:)
    hours = schedule_reminder.minutes / 60
    minutes = schedule_reminder.minutes % 60
    hours_text = "#{hours}時間" if hours.positive?
    minutes_text = "#{minutes}分" if minutes.positive?
    "#{hours_text}#{minutes_text}"
  end

  def process_notification(schedule_reminder:, schedule:, text:)
    errors = []

    schedule.user.notification_targets.each do |channel, uid|
      deliver_once(schedule_reminder:, channel:, uid:, text:)
    rescue StandardError => e
      Rails.logger.error "Notification send message error (Schedule ID: #{schedule.id}, Channel: #{channel}): #{e.class} - #{e.message}"
      errors << e
    end

    raise NotificationDeliveryError, errors.map(&:message).join('; ') if errors.present?
  end

  def deliver_once(schedule_reminder:, channel:, uid:, text:)
    delivery = NotificationDelivery.find_or_create_by!(schedule_reminder:, channel:)
    return unless delivery.claim

    case channel.to_sym
    when :line    then Line::SendMessageService.call(uid:, text:)
    when :discord then Discord::SendMessageService.call(uid:, text:)
    end
    delivery.mark_sent!
  rescue StandardError => e
    delivery&.mark_failed!(e.message)
    raise
  end
end
