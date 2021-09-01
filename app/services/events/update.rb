# frozen_string_literal: true

module Events
  # Service for updating a user's event
  class Update < BaseService
    def initialize(user_id, event_id)
      @user = User.find(user_id)
      @integration = @user.integrations.find_by(name: 'google_calendar', status: 'active')
      @event = @user.events.find_by(id: event_id)
    end

    def call(event_options)
      update_event(event_options)
    end

    private

    def update_event(event_options, send_notifications: false)
      adapter.update_event(@event.gcalendar_id,
                           event_options,
                           send_notifications: send_notifications)
      @event.update!(event_options)
    rescue StandardError => e # Customize Error types
      parse_error(e)
    end

    def adapter
      @adapter ||= ::Integrations::GoogleCalendar::Adapter.new(@user.id)
    end

    def parse_error(error)
      Rails.logger.info(error)
    end
  end
end
