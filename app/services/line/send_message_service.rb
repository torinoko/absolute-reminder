# frozen_string_literal: true
require 'line/bot'

module Line
  class SendMessageService
    def self.call(uid:, text:)
      new.call(uid: uid, text: text)
    end

    def call(uid:, text:)
      message = Line::Bot::V2::MessagingApi::TextMessage.new(
        text: text
      )
      request_body = Line::Bot::V2::MessagingApi::PushMessageRequest.new(
        to: uid,
        messages: [message]
      )

      begin
        response = client.push_message(push_message_request: request_body)
        Rails.logger.info "LINE send message success: #{response.inspect}"
        response
      rescue StandardError => e
        Rails.logger.error "LINE send message error: #{e.class} - #{e.message}"
        nil
      end
    end

    private

    def client
      @client ||= Line::Bot::V2::MessagingApi::ApiClient.new(
        channel_access_token: ENV['LINE_CHANNEL_TOKEN']
      )
    end
  end
end
