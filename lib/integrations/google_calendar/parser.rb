# frozen_string_literal: true

module Integrations
  module GoogleCalendar
    # Parser module for Google Calendar API requests/respones
    module Parser
      SUPPORTED_FIELDS = %i[summary description start end attendees reminders].freeze

      def self.parse_events(events)
        events.map do |event|
          parse_single_event(event)
        end
      end

      # TODO: Change starts_at, ends_at column types to datetime!
      # pass timestamps to parse_datetime method?
      def self.parse_single_event(event)
        {
          gcalendar_id: event.id,
          name: event.summary,
          description: event.description,
          starts_at: event.start.date_time || event.start.date.to_datetime,
          ends_at: event.end.date_time || event.end.date.to_datetime,
          recurring: event.recurrence || false,
          created_at: Time.now,
          updated_at: Time.now
        }
      rescue StandardError => e
        binding.pry # Add parse error or sth
      end

      def self.format_event_object(event_options)
        event_options[:summary] = event_options.delete :name # TODO: Change column name to summary
        event_options.map { |key, val| [key, format_values(key, val)] }.compact.to_h
      end

      def self.format_values(key, value)
        return false unless key.in?(SUPPORTED_FIELDS)

        case key
        when :start, :end
          { date_time: value }
        when :attendees
          value.map { |attendee| attendee.slice(:email) }.compact_blank
        else
          value
        end
      end
    end
  end
end
