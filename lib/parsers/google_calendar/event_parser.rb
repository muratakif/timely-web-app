# frozen_string_literal: true

# TODO: Change file structure to adapt adapter pattern!
module Parsers
  module GoogleCalendar
    module EventParser
      def self.parse_events(events)
        events.map do |event|
          parse_single_event(event)
        end
      end

      def self.parse_single_event(event)
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
end
