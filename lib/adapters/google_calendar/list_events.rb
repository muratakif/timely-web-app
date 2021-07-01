# frozen_string_literal: true

module Adapters
  module GoogleCalendar
    class ListEvents
      CONFIG_KEY = 'g_calendar'
      AUTH_URI = 'https://accounts.google.com/o/oauth2/oauth'

      # TODO: Move to env vars
      APPLICATION_NAME = "Timely Web client".freeze
      CALENDAR_ID = "primary".freeze
      DEFAULT_PAGE_SIZE = 25
      
      attr_reader :has_next_page

      def initialize(user_id, options = {})
        @has_next_page = true
        @filter = build_filter(options)
        setup_client(user_id)
      end

      def fetch_events
        response = @client.list_events(CALENDAR_ID,
                                        max_results:   @filter[:page_size],
                                        time_min:      @filter[:from].rfc3339,
                                        single_events: true,
                                        order_by:      "startTime",
                                        page_token:    @next_page_token)

        @next_page_token = response.next_page_token
        @has_next_page = false if @next_page_token.nil?
        response.items
      end

      private

      def setup_client(user_id)
        @client = Google::Apis::CalendarV3::CalendarService.new
        @client.client_options.application_name = APPLICATION_NAME
        @client.authorization = OauthClient.new(user_id).authorize
      end

      def build_filter(options)
        {
          page_size: options[:page_size] || DEFAULT_PAGE_SIZE,
          from:      options[:from] || DateTime.now
        }
      end
    end
  end
end
