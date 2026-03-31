# frozen_string_literal: true

module Google
  class Client
    attr_reader :user

    def self.call(user)
      new(user).setup_authorization
    end

    def initialize(user)
      @user = user
    end

    def setup_authorization
      # アクセストークンが期限切れの場合は、リフレッシュトークンを使って再取得
      if profile.token_expires_at.present? && profile.token_expires_at < Time.current
        client.fetch_access_token!
        profile.update!(
          access_token: client.access_token,
          token_expires_at: Time.current + client.expires_in.to_i.seconds
        )
      end

      client
    end

    private

    def profile
      @profile ||= user.user_profiles.detect { |p| p.provider == 'google_oauth2' }
    end

    def client
      @client ||=Signet::OAuth2::Client.new(
        client_id: ENV['GOOGLE_CLIENT_ID'],
        client_secret: ENV['GOOGLE_CLIENT_SECRET'],
        token_credential_uri: 'https://oauth2.googleapis.com/token',
        access_token: profile.access_token,
        refresh_token: profile.refresh_token
      )
    end
  end
end
