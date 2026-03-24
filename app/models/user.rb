# frozen_string_literal: true

class User < ApplicationRecord
  has_many :user_profiles, dependent: :destroy
  has_many :schedules, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true

  def linked_with?(provider)
    user_profiles.any? { |profile| profile.provider == provider.to_s }
  end
end
