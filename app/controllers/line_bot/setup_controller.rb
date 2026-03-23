# frozen_string_literal: true

module LineBot
  class SetupController < ApplicationController
    def show
      line_token = LineToken.find_by(token: params[:token])

      if line_token.nil? || line_token.expires_at < Time.current
        @message = 'URLの有効期限が切れています。もう一度LINEで「連携」と話しかけてください。'
      else
        session[:pending_line_uid] = line_token.uid
      end
    end
  end
end
