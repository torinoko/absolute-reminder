# frozen_string_literal: true

class LineToken < ApplicationRecord
  validates :uid, presence: true
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  def expired?
    Time.current > expires_at
  end
  def self.consume(token:, uid:)
    record = lock.find_by(token:, uid:)
    return if record.nil? || record.expired?

    record.destroy!
    record
  end
end
