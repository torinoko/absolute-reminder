# frozen_string_literal: true

class User < ApplicationRecord
  has_many :user_profiles, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
end
