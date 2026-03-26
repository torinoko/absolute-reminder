# frozen_string_literal: true

class Schedule < ApplicationRecord
  belongs_to :user
  has_many :schedule_reminders, dependent: :destroy

  validates :user_id, presence: true, uniqueness: { scope: :google_event_id }
  validates :google_event_id, presence: true
  validates :start_at, presence: true, comparison: { greater_than: Time.zone.now }
  validates :summary, presence: true

  after_commit :schedule_notification_job, on: [:create, :update]

  private

  def schedule_notification_job
    recent_reminder = schedule_reminders.last
    last_minute_reminder = schedule_reminders.first
    recent_time = self.start_at - recent_reminder.minutes
    last_minute_time = self.start_at - last_minute_reminder.minutes

    if recent_time> Time.current && !recent_reminder.notified?
      NotifySchedulesJob.set(wait_until: recent_time).perform_later(schedule_id: self.id)
    end
    if last_minute_time> Time.current && !last_minute_reminder.notified?
      NotifySchedulesJob.set(wait_until: recent_time).perform_later(schedule_id: self.id)
    end
  end

end
