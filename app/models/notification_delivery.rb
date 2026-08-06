# frozen_string_literal: true

class NotificationDelivery < ApplicationRecord
  belongs_to :schedule_reminder

  CHANNELS = %w[line discord].freeze
  LEASE_DURATION = 10.minutes

  validates :channel, presence: true, inclusion: { in: CHANNELS }
  validates :status, presence: true
  validates :attempts, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def sent?
    sent_at.present?
  end

  # Claim the delivery while holding a row lock. A live claim is treated as
  # in-flight so duplicate jobs do not send the same message concurrently.
  def claim
    with_lock do
      return false if sent?
      return false if status == 'sending' && claimed_at.present? && claimed_at > LEASE_DURATION.ago

      update!(
        status: 'sending',
        claimed_at: Time.current,
        attempts: attempts + 1,
        last_error: nil
      )
      true
    end
  end

  def mark_sent!
    update!(status: 'sent', sent_at: Time.current, claimed_at: nil, last_error: nil)
  end

  def mark_failed!(error)
    update!(status: 'failed', claimed_at: nil, last_error: error.to_s.truncate(2_000))
  end
end
