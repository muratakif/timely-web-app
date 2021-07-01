# frozen_string_literal: true

# TODO: Add rescue statements and create error classes
# TODO: Isolate/Seperate fetch API and upsert record logic
# TODO: Configure base service, implement error handling, service objects etc
# TODO: Implement real sync logic, dig into the API find some useful hook or sth
module Events
  class Sync < BaseService
    def initialize(user_id, from = nil)
      @user = User.find(user_id)
      @from = from
      @errors = []
    end

    def call
      @adapter = ::Adapters::GoogleCalendar::ListEvents.new(@user.id, from: @from)
      read_pages
    end

    private

    attr_reader :adapter, :fetched_events

    def read_pages
      loop do
        @fetched_events = adapter.fetch_events # TODO: pass from parameter as the last events' time
        sync_events
        break unless adapter.has_next_page
      end
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

      new_events = fetched_events.select { |e| new_event_ids.include?(e.id) }
      events_to_be_created = parse_events(new_events)
      @user.events.insert_all(events_to_be_created) # add bulk_insert gem
    end

    def update_old_events(existing_event_ids)
      return if existing_event_ids.empty?

      old_raw_events = fetched_events.select { |e| existing_event_ids.include?(e.id) }
      old_event_records = Event.where(gcalendar_id: existing_event_ids)
      events_to_be_synced = []

      old_event_records.each do |record|
        raw_event = old_raw_events.find(gcalendar_id: record.gcalendar_id).first
        events_to_be_synced << raw_event if record.updated_at < raw_event.updated
      end

      parsed_events = parse_events(events_to_be_synced)
      @user.events.where(gcalendar_id: events_to_be_synced.map(&:id)).update_all(parsed_events) unless parsed_events.empty?
    end

    def parse_events(events)
      events.map do |event|
        parse_single_event(event)
      end
    end

    # TODO: Implement a Parser class/module maybe?
    # TODO: Change starts_at, ends_at column types to datetime!
    def parse_single_event(event)
      {
        gcalendar_id: event.id,
        name:         event.summary,
        description:  event.description,
        starts_at:    event.start.date_time || e.start.date, # pass it to parse_datetime method
        ends_at:      event.end.date_time || e.end.date, # pass it to parse_datetime method
        recurring:    event.recurrence || false,
        created_at:   Time.now,
        updated_at:   Time.now
      }
    end
  end
end