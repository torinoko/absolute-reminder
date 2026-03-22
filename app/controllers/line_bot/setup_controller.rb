# frozen_string_literal: true

module LineBot
  class SetupController < ApplicationController
    def show
      line_token = LineToken.find_by(token: params[:token])

      if line_token.nil? || line_token.expires_at < Time.current
        return render plain: "URLの有効期限が切れています。もう一度LINEで「連携」と話しかけてください。"
      end

      session[:pending_line_uid] = line_token.uid

      redirect_to '/auth/google_oauth2'
    end
  end
end