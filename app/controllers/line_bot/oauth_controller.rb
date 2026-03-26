# frozen_string_literal: true

module LineBot
  class OauthController < ApplicationController
    before_action :require_login

    def login
      session[:line_oauth_state] = SecureRandom.hex(16)

      redirect_url = Line::Client.authorize_url(
        state: session[:line_oauth_state],
        redirect_uri: line_callback_url
      )

      redirect_to redirect_url, allow_other_host: true
    end

    def callback
      if params[:state] != session[:line_oauth_state]
        return redirect_to root_path, alert: '不正なアクセスです。'
      end

      token_response = Line::Client.fetch_token(
        code: params[:code],
        redirect_uri: line_callback_url
      )

      access_token = token_response['access_token']
      profile_response = Line::Client.fetch_profile(access_token)

      current_user.user_profiles.find_or_initialize_by(provider: 'line').update!(
        uid: profile_response['userId'],
        access_token: access_token,
        refresh_token: token_response['refresh_token'],
        raw_info: profile_response
      )

      redirect_to root_path, notice: 'LINEアカウントを連携しました！'
    end
  end
end
