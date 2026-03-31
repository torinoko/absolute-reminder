# frozen_string_literal: true

module LineBot
  class SetupController < ApplicationController
    def show
      line_token = LineToken.find_by(token: params[:token])

      if line_token.nil? || line_token.expired?
        redirect_to root_url
      else
        session[:pending_line_uid] = line_token.uid
        session[:pending_line_token] = line_token.token
        line_token.destroy
      end
    end
  end
end