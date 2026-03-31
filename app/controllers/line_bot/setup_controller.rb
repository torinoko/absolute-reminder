# frozen_string_literal: true

module LineBot
  class SetupController < ApplicationController
    def show
      line_token = LineToken.find_by(token: params[:token])

      if line_token.nil? || line_token.expired? || session[:pending_line_uid].blank?
        redirect_to root_url
      else
        session[:pending_line_uid] = line_token.uid
        session[:pending_line_token] = line_token.token
        # ここで LineToken を削除する実装にすると期待した表示がされない
        # （LINE で URL を表示したときに一回アクセされるっぽい？？）
      end
    end
  end
end
