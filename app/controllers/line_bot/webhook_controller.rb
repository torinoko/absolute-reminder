# frozen_string_literal: true

module LineBot
  require 'line/bot'

  class WebhookController < ApplicationController
    protect_from_forgery except: :create

    def create
      body = request.body.read
      signature = request.env['HTTP_X_LINE_SIGNATURE']

      parser = Line::Bot::V2::WebhookParser.new(
        channel_secret: ENV['LINE_CHANNEL_SECRET']
      )

      begin
        events = parser.parse(body: body, signature: signature)
      rescue StandardError => e
        Rails.logger.error "Webhook parse error: #{e.message}"
        return head :bad_request
      end

      events.each do |event|
        case event
        when Line::Bot::V2::Webhook::FollowEvent
          uid = event.source.user_id
          token = SecureRandom.urlsafe_base64
          LineToken.create!(uid: uid, token: token, expires_at: 1.hour.since)
          link_url = "#{root_url}line_bot/setup?token=#{token}&openExternalBrowser=1"

          message = Line::Bot::V2::MessagingApi::TextMessage.new(
            text: "#{application_name}へようこそ！🐦\n予定を通知するために、以下のリンクからGoogleカレンダーと連携してください。\n#{link_url}"
          )

          request_body = Line::Bot::V2::MessagingApi::ReplyMessageRequest.new(
            reply_token: event.reply_token,
            messages: [message]
          )

          client.reply_message(reply_message_request: request_body)
        end
      end

      head :ok
    end

    private

    def client
      @client ||= Line::Bot::V2::MessagingApi::ApiClient.new(
        channel_access_token: ENV['LINE_CHANNEL_TOKEN']
      )
    end
  end
end
