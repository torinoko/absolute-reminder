# frozen_string_literal: true

module Google
  class Calendar
    TARGET_KEYWORD = '！'

    attr_reader :service

    def self.call(user)
      new(user).fetch_events
    end

    def initialize(user)
      @service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = Google::Client.call(user)
    end

    def fetch_events
      events = service.list_events(
        'primary',
        q: TARGET_KEYWORD,
        time_min: Time.current.iso8601,
        time_max: 6.hour.since.iso8601,
        single_events: true,
        order_by: 'startTime'
      )

      events.items.select do |event|
        event.start.date_time.present? && event.start.date_time > Time.current && event.summary.include?(TARGET_KEYWORD)
      end
    end

    def include_keyword?(event)
      event.summary
    end
  end
end
