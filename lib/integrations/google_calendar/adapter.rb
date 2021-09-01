# frozen_string_literal: true

module Integrations
  module GoogleCalendar
    # Adapter class for using GoogleCalendar API
    class Adapter
      APPLICATION_NAME = 'Timely Web client' # TODO: Move to env vars
      CALENDAR_ID = 'primary'

      DEFAULT_PAGE_SIZE = 100
      DEFAULT_EVENT_FIELDS = %w[id summary description start end recurrence updated status].freeze
      API_SUPPORTED_EVENT_FIELDS = %w[attendees conference_data created creator
                                      description end etag event_type hangout_link
                                      html_link i_cal_uid id kind organizer reminders
                                      sequence start status summary updated].freeze

      attr_reader :has_next_page, :sync_token

      def initialize(user_id, options = {})
        @sync_token = options[:sync_token]
        @has_next_page = true
        @filter = build_filter(options)

        setup_client(user_id)
      end

      def fetch_all
        events = []

        loop do # Can we split this into threads?
          events << fetch_single_page
          break unless has_next_page
        end

        events.flatten
      end

      def fetch_single_page
        response = fetch_from_client

        @sync_token = response.next_sync_token if response.next_sync_token
        @next_page_token = response.next_page_token
        @has_next_page = false if @next_page_token.nil?

        response.items
      end

      def update_event(event_id, event_options, send_notifications: false)
        @client.patch_event(CALENDAR_ID,
                            event_id,
                            build_event_object(event_options),
                            send_notifications: send_notifications,
                            fields: request_fields(:single))
      end

      def create_event(event_options, send_notifications: false)
        @client.insert_event(CALENDAR_ID,
                             build_event_object(event_options),
                             send_notifications: send_notifications,
                             fields: request_fields(:single))
      end

      def get_event(event_id)
        @client.get_event(CALENDAR_ID, event_id)
      end

      private

      attr_reader :client

      def build_filter(options)
        {
          page_size: options[:page_size] || DEFAULT_PAGE_SIZE,
          from: options[:from] || DateTime.now
        }
      end

      # TODO: Implement revoked or expired token failover
      def setup_client(user_id)
        @client = Google::Apis::CalendarV3::CalendarService.new
        @client.client_options.application_name = APPLICATION_NAME
        @client.authorization = OauthClient.new(user_id).authorize
      end

      def fetch_from_client
        client.list_events(CALENDAR_ID,
                           max_results: @filter[:page_size],
                           single_events: true,
                           sync_token: @sync_token,
                           page_token: @next_page_token,
                           fields: request_fields(:list))
      rescue StandardError => e
        binding.pry
      end

      def build_event_object(event_options)
        Parser.format_event_object(event_options.deep_dup)
      end

      def request_fields(request_type, extra_fields = [])
        valid_extra_fields = extra_fields.intersection(API_SUPPORTED_EVENT_FIELDS)
        all_fields = valid_extra_fields.concat(DEFAULT_EVENT_FIELDS).join(',')

        case request_type
        when :single
          all_fields
        when :list
          "items(#{all_fields}),next_sync_token,next_page_token"
        end
      end
    end
  end
end
