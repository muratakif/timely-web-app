# frozen_string_literal: true

# TODO: Add rescue statements and create error classes
# TODO: Isolate/Seperate fetch API and upsert record logic?
# TODO: Configure base service, implement error handling, service objects etc
# TODO: Implement real sync logic, dig into the API find some useful hook or sth
module Events
  # Service for syncing a user's events
  class Sync < BaseService
    def initialize(user_id, from: nil)
      @user = User.includes(:events).find(user_id)
      @integration = @user.integrations.find_by(name: 'google_calendar', status: 'active')
      @from = from
    end

    def call
      read_pages
      @user.update(last_checked_in: Time.current)
      @integration.update(sync_token: adapter.sync_token) if adapter.sync_token
    end

    private

    attr_reader :fetched_events

    # Can we split this into seperate workers? It can take too long!
    def read_pages
      loop do
        @fetched_events = adapter.fetch_single_page
        sync_events
        break unless adapter.has_next_page
      end
    end

    def adapter
      @adapter ||= ::Integrations::GoogleCalendar::Adapter.new(
        @user.id,
        sync_token: @integration&.sync_token,
        from: @from
      )
    end

    def sync_events
      # what happens if an old event is updated? is next_page_token enough?
      all_event_ids = fetched_events.map(&:id)
      # maybe memoize this?
      existing_event_ids = @user.events.select(:id)
                                .where(gcalendar_id: all_event_ids)
                                .pluck(:gcalendar_id)
      new_event_ids = all_event_ids - existing_event_ids

      update_old_events(existing_event_ids)
      create_new_events(new_event_ids)
    end

    def create_new_events(new_event_ids)
      return if new_event_ids.empty?

      new_events = @fetched_events.select { |e| new_event_ids.include?(e.id) }
      events_to_be_created = parse_events(new_events)
      @user.events.insert_all(events_to_be_created) # add bulk_insert gem
    end

    def update_old_events(existing_event_ids)
      return if existing_event_ids.empty?

      old_raw_events = fetched_events.select { |e| existing_event_ids.include?(e.id) }
      old_event_records = @user.events.where(gcalendar_id: existing_event_ids)
      parsed_events = parse_events(old_raw_events)

      old_event_records.each do |record|
        parsed_event = parsed_events.find(gcalendar_id: record.gcalendar_id).first
        record.update!(parsed_event)
      end
    end

    def parse_events(events)
      ::Integrations::GoogleCalendar::Parser.parse_events(events)
    end
  end
end
