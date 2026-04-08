# frozen_string_literal: true

module Google
  class Calendar
    TARGET_KEYWORD = '！'

    attr_reader :service, :user

    def self.call(user)
      new(user).fetch_events
    end

    def initialize(user)
      @user = user
      @service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = Google::Client.call(user)
    end

    def fetch_events
      events = service.list_events(
        'primary',
        q: TARGET_KEYWORD,
        time_min: Time.current.iso8601,
        time_max: 24.hours.since.iso8601,
        single_events: true,
        order_by: 'startTime'
      )

      events.items.select do |event|
        event.start.date_time.present? && later_than_now?(event:) && include_keyword?(event:)
      end

    rescue Google::Apis::AuthorizationError
      Rails.logger.info "Google access token expired error: User ID: #{user.id}"
      service.authorization.fetch_access_token!
      retry
    rescue Signet::AuthorizationError => e
      Rails.logger.info "Google access token invalid error. User ID: #{user.id}"
    end

    private

    def later_than_now?(event:)
      event.start.date_time > Time.current
    end

    def include_keyword?(event:)
      event.summary.include?(TARGET_KEYWORD)
    end
  end
end
