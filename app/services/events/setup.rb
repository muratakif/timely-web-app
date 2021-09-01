# frozen_string_literal: true

# TODO: Add rescue statements and create error classes
# TODO: Isolate/Seperate fetch API and upsert record logic?
# TODO: Configure base service, implement error handling, service objects etc
module Events
  # Service for syncing a user's events
  class Setup < BaseService
    def initialize(user_id, from: nil)
      @user = User.includes(:events).find(user_id)
    end

    def call
      # TODO: Change integration$name column to service
      @integration = @user.integrations.create!(name: 'google_calendar', status: 'active')
      read_pages
      @integration.update(sync_token: adapter.sync_token, last_synced: Time.current) if adapter.sync_token
    end

    private

    attr_reader :fetched_events

    def read_pages
      loop do
        @fetched_events = adapter.fetch_single_page
        create_new_events
        break unless adapter.has_next_page
      end
    end

    def adapter
      @adapter ||= ::Integrations::GoogleCalendar::Adapter.new(
        @user.id,
        sync_token: @integration.sync_token
      )
    end

    def create_new_events
      # I chose to not create an event if it's status is "cancelled"
      # As the API does not provide no information apart from google_calendar_id and status fields
      raw_events = fetched_events.select { |event| event.status != 'cancelled' }
      
      return if raw_events.empty?

      events_to_be_created = parse_events(raw_events)
      @user.events.insert_all(events_to_be_created) # add bulk_insert gem
    end

    def parse_events(events)
      ::Integrations::GoogleCalendar::Parser.parse_events(events)
    end
  end
end
