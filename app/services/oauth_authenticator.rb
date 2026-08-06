# frozen_string_literal: true

# OauthAuthenticator:
# - 認証情報を DB に保存する
class OauthAuthenticator
  attr_reader :auth_hash, :user, :uid

  def self.call(auth_hash, pending_line_uid: nil, pending_line_token: nil)
    new(auth_hash, pending_line_uid:, pending_line_token:).authenticate
  end

  def initialize(auth_hash, pending_line_uid:, pending_line_token:)
    @auth_hash          = auth_hash
    @provider           = auth_hash[:provider]
    @uid                = auth_hash[:uid]
    @pending_line_uid   = pending_line_uid
    @pending_line_token = pending_line_token
  end

  def authenticate
    ActiveRecord::Base.transaction do
      @user = find_or_create_user!
      update_or_create_user_profile!(auth_hash:)
      line_token = consume_line_token
      update_or_create_user_profile!(auth_hash: line_auth_hash(line_token:)) if line_token
      user
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("OAuth Authentication error: #{e.message}")
    nil
  end

  private

  def find_or_create_user!
    email = auth_hash.dig(:info, :email)
    user = UserProfile.find_by(provider: :google_oauth2, uid:)&.user
    if user
      user.update!(email: email) if email
      return user
    else
      User.create!(
        email: email || "dummy+#{uid}@example.com",
        name: auth_hash.dig(:info, :name) || '名無しさん'
      )
    end
  end

  def consume_line_token
    return if @pending_line_token.blank? || @pending_line_uid.blank?

    LineToken.consume(token: @pending_line_token, uid: @pending_line_uid)
  end

  def line_auth_hash(line_token:)
    uid = line_token.uid
    token = line_token.token
    google_uid = user.user_profiles.find_by(provider: :google_oauth2)&.uid
    { provider: :line, uid:, google_uid:, credentials: { token: } }
  end

  def update_or_create_user_profile!(auth_hash:)
    provider = auth_hash[:provider]
    uid      = auth_hash[:uid]
    profile  = user.user_profiles.find_or_initialize_by(provider:, uid:)
    raw_info = auth_hash.dig(:extra, :raw_info).to_h
    new_refresh_token = auth_hash.dig(:credentials, :refresh_token)

    profile.update!(
      access_token: auth_hash.dig(:credentials, :token),
      refresh_token: new_refresh_token || profile.refresh_token,
      raw_info: raw_info
    )
  end
end
