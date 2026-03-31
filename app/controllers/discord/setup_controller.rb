# frozen_string_literal: true

module Discord
  class SetupController < ApplicationController
    before_action :require_login

    def show
      session[:discord_oauth_state] = SecureRandom.hex(16)
      redirect_to discord_oauth_url(state: session[:discord_oauth_state]), allow_other_host: true
    end

    private

    def discord_oauth_url(state:)
      client_id     = ENV['DISCORD_CLIENT_ID']
      scope         = 'identify'
      response_type = 'code'

      "https://discord.com/api/oauth2/authorize" \
        "?client_id=#{client_id}" \
        "&redirect_uri=#{discord_callback_url}" \
        "&response_type=#{response_type}" \
        "&scope=#{scope}" \
        "&state=#{state}"
    end
  end
end
