# frozen_string_literal: true

class OauthAuthenticator
  attr_reader :auth_hash, :uid, :provider

  def self.call(auth_hash)
    new(auth_hash).authenticate
  end

  def initialize(auth_hash)
    @auth_hash = auth_hash
    @provider = auth_hash[:provider]
    @uid = auth_hash[:uid]
  end

  def authenticate
    ActiveRecord::Base.transaction do
      user = find_or_create_user!
      update_or_create_authentication!(user)
      user
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("OAuth Authentication error: #{e.message}")
    nil
  end

  private

  def find_or_create_user!
    email = auth_hash.dig(:info, :email)
    user = User.find_by(email: email) if email.present?
    return user if user

    User.create!(
      email: email || "dummy+#{uid}example.com",
      name: auth_hash.dig(:info, :name) || '名無しさん'
    )
  end

  def update_or_create_authentication!(user)
    profile = UserProfile.find_or_initialize_by(provider:, uid:)

    raw_info = auth_hash.dig(:extra, :raw_info).to_h
    new_refresh_token = auth_hash.dig(:credentials, :refresh_token)

    profile.update!(
      user: user,
      access_token: auth_hash.dig(:credentials, :token),
      refresh_token: new_refresh_token || profile.refresh_token,
      raw_info: raw_info
    )
  end
end
