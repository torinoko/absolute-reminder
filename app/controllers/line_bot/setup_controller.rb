# frozen_string_literal: true
require 'line/bot'

module LineBot
  class OauthController < ApplicationController
    protect_from_forgery

    attr_reader :token

    def show
      line_token = LineToken.find_by(token: params[:token])

      if line_token.nil? || line_token.expires_at < Time.current
        redirect_to root_url
      else
        session[:pending_line_uid] = line_token.uid
        session[:pending_line_token] = line_token.token
      end
    end

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

      @token = SecureRandom.urlsafe_base64
      follow_event(events)

      head :ok
    end

    private

    def follow_event(events)
      events.each do |event|
        case event
        when Line::Bot::V2::Webhook::FollowEvent
          uid = event.source.user_id
          LineToken.create!(uid: uid, token: token, expires_at: 1.hour.since)
          send_message(event)
        end
      end
    end

    def send_message(event)
      message = Line::Bot::V2::MessagingApi::TextMessage.new(text:)
      request_body = Line::Bot::V2::MessagingApi::ReplyMessageRequest.new(
        reply_token: event.reply_token,
        messages: [message]
      )
      client.reply_message(reply_message_request: request_body)
    end

    def text
      link_url = "#{root_url}line_bot/oauth?token=#{token}&openExternalBrowser=1"
      "#{application_name}へようこそ！🐦\n予定を通知するために、以下のリンクからGoogleカレンダーと連携してください。\n#{link_url}"
    end

    def client
      @client ||= Line::Bot::V2::MessagingApi::ApiClient.new(
        channel_access_token: ENV['LINE_CHANNEL_TOKEN']
      )
    end
  end
end
