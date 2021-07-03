# frozen_string_literal: true

module Integrations
  module GoogleCalendar
    # Adapter class for using GoogleCalendar API
    class Adapter
      # CONFIG_KEY = 'g_calendar'
      # AUTH_URI = 'https://accounts.google.com/o/oauth2/oauth'

      # TODO: Move to env vars
      APPLICATION_NAME = 'Timely Web client'
      CALENDAR_ID = 'primary'
      DEFAULT_PAGE_SIZE = 100

      attr_reader :has_next_page, :sync_token

      def initialize(user_id, options = {})
        @sync_token = options[:sync_token]
        @has_next_page = true
        @filter = build_filter(options)
        setup_client(user_id)
      end

      def fetch_all
        # Can we split this into threads?
        events = []
        loop do
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

      private

      attr_reader :client

      def build_filter(options)
        {
          page_size: options[:page_size] || DEFAULT_PAGE_SIZE,
          from: options[:from] || DateTime.now
        }
      end

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
                           fields: requested_fields)
      end

      def requested_fields
        'items(id,summary,description,start,end,recurrence,updated),next_sync_token, next_page_token'
      end
    end
  end
end
