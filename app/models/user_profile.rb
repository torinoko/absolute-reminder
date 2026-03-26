class UserProfile < ApplicationRecord
  belongs_to :user

  encrypts :access_token, :refresh_token

  validates :user_id, presence: true
  validates :provider, presence: true, uniqueness: { scope: :user_id }
  validates :uid, presence: true, uniqueness: { scope: :user_id }
end
