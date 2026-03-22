# frozen_string_literal: true
require 'line/bot'

module Line
  class WebhooksController < ApplicationController
    protect_from_forgery except: :create

    def create
      body = request.body.read
      events = client.parse_events_from(body)

      events.each do |event|
        case event
        when Line::Bot::Event::Follow
          line_user_id = event['source']['userId']

          token = SecureRandom.urlsafe_base64
          LinkToken.create!(line_uid: line_user_id, token: token, expires_at: 1.hour.since)

          link_url = setup_link_url(token: token)
          message = {
            type: 'text',
            text: "#{applicaton_name} へようこそ！🕊️\n予定を通知するために、以下のリンクから Google カレンダーと連携してください。\n#{link_url}"
          }
          client.reply_message(event['replyToken'], message)
        end
      end

      head :ok
    end

    private

    def client
      @client ||= Line::Bot::Client.new do |config|
        config.channel_secret = ENV['LINE_CHANNEL_SECRET']
        config.channel_token = ENV['LINE_CHANNEL_TOKEN']
      end
    end
  end
end
