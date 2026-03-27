# frozen_string_literal: true

module Discord
  class OauthController < ApplicationController
    protect_from_forgery except: :create
    before_action :require_login

    def new
      session[:discord_oauth_state] = SecureRandom.hex(16)
      redirect_to discord_oauth_url(state: session[:discord_oauth_state]), allow_other_host: true
    end

    def create
      code = params['code']
      unless code
        @message = '連携に失敗しました。'
        render '/error', status: :bad_request
        return
      end

      if params['state'] != session[:discord_oauth_state]
        @message = '不正なアクセスです。'
        render '/error', status: :bad_request
        return
      end
      session.delete(:discord_oauth_state)

      token_response = exchange_code_for_token(code)
      access_token = token_response['access_token']
      create_user_profile(access_token)
      redirect_to root_path
    end

    private

    def discord_oauth_url(state:)
      client_id     = ENV['DISCORD_CLIENT_ID']
      redirect_uri  = CGI.escape(ENV['DISCORD_REDIRECT_URI'])
      scope         = 'identify'
      response_type = 'code'

      "https://discord.com/api/oauth2/authorize" \
        "?client_id=#{client_id}" \
        "&redirect_uri=#{redirect_uri}" \
        "&response_type=#{response_type}" \
        "&scope=#{scope}" \
        "&state=#{state}"
    end

    def exchange_code_for_token(code)
      return if code.blank?

      uri = URI("https://discord.com/api/oauth2/token")
      res = Net::HTTP.post_form(uri, {
        "client_id" => ENV["DISCORD_CLIENT_ID"],
        "client_secret" => ENV["DISCORD_CLIENT_SECRET"],
        "grant_type" => "authorization_code",
        "code" => code,
        "redirect_uri" => ENV["DISCORD_REDIRECT_URI"]
      })

      if res.code == "200"
        JSON.parse(res.body)
      else
        Rails.logger.error "Discord access_token error"
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
