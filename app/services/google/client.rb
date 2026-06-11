# frozen_string_literal: true

module Google
  class Client
    attr_reader :user

    def initialize(user)
      @user = user
    end

    # Google APIを安全に実行するための共通メソッド
    # 使い方: client.execute { |g_client| g_client.list_calendar_events(...) }
    def execute
      yield(authorization_client)
    rescue Signet::AuthorizationError, Google::Apis::AuthorizationError => e
      # トークンエラー（期限切れなど）が発生したら、リフレッシュして1度だけ再試行する
      Rails.logger.warn("Google Access Token expired, attempting refresh...: #{e.message}")

      refresh_token!

      # 新しいトークンで再実行
      yield(authorization_client)
    end

    private

    def profile
      @profile ||= user.user_profiles.find_by(provider: 'google_oauth2')
    end

    def authorization_client
      return @authorization_client if @authorization_client

      @authorization_client = Signet::OAuth2::Client.new(
        client_id: ENV.fetch('GOOGLE_CLIENT_ID', nil),
        client_secret: ENV.fetch('GOOGLE_CLIENT_SECRET', nil),
        token_credential_uri: 'https://oauth2.googleapis.com/token',
        access_token: profile&.access_token,
        refresh_token: profile&.refresh_token
      )

      # Signetが内部で自動リフレッシュした際、DBのトークンも同期して更新するコールバック
      @authorization_client.on_refresh do |new_credentials|
        profile.update!(
          access_token: new_credentials.access_token,
          refresh_token: new_credentials.refresh_token || profile.refresh_token,
          token_expires_at: Time.current + @authorization_client.expires_in.to_i.seconds
        )
      end

      @authorization_client
    end

    # 明示的にトークンを更新してDBに保存する
    def refresh_token!
      return unless profile&.refresh_token

      authorization_client.fetch_access_token!
    end
  end
end
