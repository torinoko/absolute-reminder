# frozen_string_literal: true

module Discord
  class SendMessageService
    BASE_URL = "https://discord.com/api/v10"

    def self.call(uid:, text:)
      new.call(uid: uid, text: text)
    end

    def call(uid:, text:)
      dm_channel_id = create_dm_channel(uid)
      return unless dm_channel_id

      send_message(dm_channel_id, text)
    end

    private

    def create_dm_channel(uid)
      response = post_request("/users/@me/channels", { recipient_id: uid })

      if response.is_a?(Net::HTTPSuccess)
        JSON.parse(response.body)['id']
      else
        Rails.logger.error("Discord DM channel error: #{response.code} - #{response.body}")
        nil
      end
    rescue JSON::ParserError => e
      Rails.logger.error("Discord JSON parse error: #{e.message}")
      nil
    end

    def send_message(channel_id, text)
      response = post_request("/channels/#{channel_id}/messages", { content: text })

      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.error("Discord message send error: #{response.code} - #{response.body}")
      end

      response
    end

    def post_request(path, payload)
      uri = URI.parse("#{BASE_URL}#{path}")
      req = Net::HTTP::Post.new(uri)
      req['Authorization'] = "Bot #{ENV['DISCORD_BOT_TOKEN']}"
      req['Content-Type'] = 'application/json'
      req.body = payload.to_json

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 5) do |http|
        http.request(req)
      end
    end
  end
end
