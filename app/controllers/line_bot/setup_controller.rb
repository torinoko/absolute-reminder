# frozen_string_literal: true

module LineBot
  class SetupController < ApplicationController
    def show
      line_token = LineToken.find_by(token: params[:token])

      if line_token.nil? || line_token.expires_at < Time.current
        redirect_to root_url
      else
        session[:pending_line_uid] = line_token.uid
        session[:pending_line_token] = line_token.token
      end
    end
  end
end
