# frozen_string_literal: true

class LineToken < ApplicationRecord
  validates :uid, presence: true
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  def expired?
    Time.current > expires_at
  end
end
