# frozen_string_literal: true

class UserProfile < ApplicationRecord
  belongs_to :user

  encrypts :access_token, :refresh_token

  # A provider account must belong to exactly one application user.  Keeping
  # this validation in addition to the database constraint makes duplicate
  # link attempts fail before an insert is attempted.
  validates :provider, presence: true, uniqueness: { scope: :user_id }
  validates :uid, presence: true, uniqueness: { scope: :provider }
end
