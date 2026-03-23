# frozen_string_literal: true

module Google
  class Calendar
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
        time_min: Time.current.iso8601,
        time_max: 6.hour.since.iso8601,
        single_events: true,
        order_by: 'startTime'
      )

      events.items.select do |event|
        start_time = event.start.date_time
        start_time.present? && start_time > Time.current
      end
    end
  end
end
