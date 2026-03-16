# frozen_string_literal: true

module Google
  class Calendar
    attr_reader :user

    def self.call(user)
      @user = user
      new(user).fetch_events
    end

    def initialize(user)
      @user = user
      @service = Google::Apis::CalendarV3::CalendarService.new
      @service.authorization = Google::Client.call(user)
    end

    def fetch_events
      @service.list_events(
        'primary',
        time_min: Time.current.iso8601,
        time_max: 6.hour.since.iso8601,
        single_events: true,
        order_by: 'startTime'
      )
    end
  end
end
