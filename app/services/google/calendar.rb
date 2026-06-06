# frozen_string_literal: true

module Google
  class Calendar
    TARGET_KEYWORD = '！'

    attr_writer :user, :service, :client

    def self.call(user)
      new(user).list_events
    end

    def initialize(user)
      @user = user
      @client = Google::Client.new(user)
      @service = Google::Apis::CalendarV3::CalendarService.new
    end

    def list_events
      events = client.execute do |auth|
        service.authorization = auth
        service.list_events(
          'primary',
          q: TARGET_KEYWORD,
          time_min: Time.current.iso8601,
          time_max: 24.hours.since.iso8601,
          single_events: true,
          order_by: 'startTime'
        )
      end

      events.items.select do |event|
        event.start.date_time.present? && later_than_now?(event:) && include_keyword?(event:)
      end
    end

    private

    attr_reader :user, :service, :client

    def later_than_now?(event:)
      event.start.date_time > Time.current
    end

    def include_keyword?(event:)
      event.summary.include?(TARGET_KEYWORD)
    end
  end
end
