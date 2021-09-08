# frozen_string_literal: true

# TODO: Add rescue statements and create error classes
# TODO: Isolate/Seperate fetch API and upsert record logic?
# TODO: Configure base service, implement error handling, service objects etc
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
      @user.update(last_checked_in: Time.current) # update integration's last_checked_in instead
      @integration.update(sync_token: adapter.sync_token) if adapter.sync_token
    end

    private

    attr_reader :fetched_events

    # Can we split this into seperate workers? It can take too long!
    # Since it's already in a worker, and I fetch the events with pagination
    # No need to split into smaller workers
    # But it should pick up from where it's left in case of failure
    # So, there may be a smarter check for last_checked_in and retry logic
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
      all_event_ids = fetched_events.map(&:id)
      # maybe memoize this?
      existing_event_ids = @user.events.select(:gcalendar_id)
                                .where(gcalendar_id: all_event_ids)
                                .pluck(:gcalendar_id)
      new_event_ids = all_event_ids - existing_event_ids

      update_old_events(existing_event_ids)
      create_new_events(new_event_ids)
    end

    def create_new_events(new_event_ids)
      # I chose not to create an event if it's status is "cancelled"
      # As the API does not provide any information apart from google_calendar_id and status fields
      # This issue occurs when an event is created and then deleted before the worker fetches it.
      new_events = @fetched_events.select do |raw_event|
        raw_event.id.in?(new_event_ids) && raw_event.status != 'cancelled'
      end
      
      return if new_events.empty?

      events_to_be_created = parse_events(new_events)
      @user.events.insert_all(events_to_be_created) # add bulk_insert gem
    end

    # TODO: Refactor here: Split update and delete logic
    def update_old_events(existing_event_ids)
      return if existing_event_ids.empty?

      old_raw_events = fetched_events.select { |e| existing_event_ids.include?(e.id) }
      old_event_records = @user.events.where(gcalendar_id: existing_event_ids)

      events_to_be_deleted = old_raw_events.select { |raw_event| raw_event.status == 'cancelled' }
      delete_old_events(events_to_be_deleted.map(&:id))
      
      events_to_be_updated = old_raw_events - events_to_be_deleted
      parsed_events = parse_events(events_to_be_updated)

      old_event_records.each do |record|
        parsed_event = parsed_events.find(gcalendar_id: record.gcalendar_id).first
        record.update!(parsed_event.except(:gcalendar_id))
      end
    end

    def delete_old_events(to_be_deleted_ids)
      @user.events.where(gcalendar_id: to_be_deleted_ids).delete_all
    end

    def parse_events(events)
      ::Integrations::GoogleCalendar::Parser.parse_events(events)
    end
  end
end
