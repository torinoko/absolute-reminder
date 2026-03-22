# frozen_string_literal: true

module Line
  class SetupLinksController < ApplicationController
    def show
      link_token = LinkToken.find_by(token: params[:token])

      if link_token.nil? || link_token.expires_at < Time.current
        return render plain: "URLの有効期限が切れています。もう一度LINEで「連携」と話しかけてください。"
      end

      session[:pending_line_uid] = link_token.line_uid

      redirect_to '/auth/google_oauth2'
    end
  end
end