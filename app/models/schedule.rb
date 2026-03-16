# frozen_string_literal: true

class Schedule < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true, uniqueness: { scope: :google_event_id }
  validates :google_event_id, presence: true
  validates :start_at, presence: true, comparison: { greater_than: Time.zone.now }
  validates :summary, presence: true
end
