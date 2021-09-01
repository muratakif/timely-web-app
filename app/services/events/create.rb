# frozen_string_literal: true

module Events
  # Service for updating a user's event
  class Create < BaseService
    def initialize(user_id)
      @user = User.find(user_id)
      @integration = @user.integrations.find_by(name: 'google_calendar', status: 'active')
    end

    def call(event_options)
      create_event(event_options)
    end

    private

    def create_event(event_options, send_notifications: false)
      response = adapter.create_event(event_options, send_notifications: send_notifications)
      parsed_response = parse_event(response)
      @user.events.create!(parsed_response)
    rescue StandardError => e # Customize Error types
      parse_error(e)
    end

    def adapter
      @adapter ||= ::Integrations::GoogleCalendar::Adapter.new(@user.id)
    end

    def parse_event(event)
      ::Integrations::GoogleCalendar::Parser.parse_single_event(event)
    end

    def parse_error(error)
      Rails.logger.info(error)
    end
  end
end
