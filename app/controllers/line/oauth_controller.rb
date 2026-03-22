# frozen_string_literal: true

module Line
  class OauthController < ApplicationController
    before_action :require_login # 既にGoogle等でログイン済みであることを前提とする

    def login
      # CSRF対策のためのランダムな文字列（state）をセッションに保存
      session[:line_oauth_state] = SecureRandom.hex(16)

      redirect_url = Line::Client.authorize_url(
        state: session[:line_oauth_state],
        redirect_uri: line_callback_url
      )

      # LINEの認証画面へリダイレクト（Turboをオフにするため status: 303 を指定すると安全です）
      redirect_to redirect_url, allow_other_host: true
    end

    def callback
      # 1. CSRF攻撃の検証
      if params[:state] != session[:line_oauth_state]
        return redirect_to root_path, alert: '不正なアクセスです。'
      end

      # 2. トークンとプロフィールの取得
      token_response = Line::Client.fetch_token(
        code: params[:code],
        redirect_uri: line_callback_url
      )

      # エラーハンドリング（token_response['error'] がある場合など）は適宜追加してください
      access_token = token_response['access_token']
      profile_response = Line::Client.fetch_profile(access_token)

      # 3. UserProfileへの保存（トランザクションやService Objectへの切り出し推奨）
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
