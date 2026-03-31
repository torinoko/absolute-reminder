# frozen_string_literal: true

module Discord
  class CallbackController < ApplicationController
    before_action :require_login

    def create
      code = params['code']
      unless code
        @message = '連携に失敗しました。'
        return render '/error', status: :bad_request
      end

      if params['state'] != session[:discord_oauth_state]
        @message = '不正なアクセスです。'
        return render '/error', status: :bad_request
      end
      session.delete(:discord_oauth_state)

      token_response = exchange_code_for_token(code)
      unless token_response
        @message = '連携に失敗しました。'
        return render '/error', status: :bad_request
      end
      access_token = token_response['access_token']
      create_user_profile(access_token)
      redirect_to root_path
    end

    private

    def exchange_code_for_token(code)
      uri = URI("https://discord.com/api/oauth2/token")
      res = Net::HTTP.post_form(uri, {
        "client_id" => ENV["DISCORD_CLIENT_ID"],
        "client_secret" => ENV["DISCORD_CLIENT_SECRET"],
        "grant_type" => "authorization_code",
        "code" => code,
        "redirect_uri" => discord_callback_url
      })

      if res.code == "200"
        JSON.parse(res.body)
      else
        Rails.logger.error "Discord access_token error"
        return false
      end
    end

    def create_user_profile(access_token)
      uri = URI("https://discord.com/api/users/@me")
      req = Net::HTTP::Get.new(uri)
      req["Authorization"] = "Bearer #{access_token}"

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end
      request_body = JSON.parse(res.body)

      current_user.user_profiles.find_or_create_by!(provider: :discord, uid: request_body["id"])
    end
  end
end
