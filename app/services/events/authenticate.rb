# frozen_string_literal: true

module Events
  # Service for authenticating users to Google Calendar API
  class Authenticate < BaseService
    APPLICATION_NAME = 'Timely Web client' # TODO: Move to env vars

    def initialize(user_id, token)
      @user_id = user_id
      @token = token
      @errors = []
    end

    def call
      validate!
      setup_client
      authenticate_gcalendar
    end

    private

    def validate!
      # ....
    end

    def authenticate_gcalendar
      # ....
    end

    def setup_client(user_id)
      @client = Google::Apis::CalendarV3::CalendarService.new
      @client.client_options.application_name = 'Timely Web client' # TODO: Move to env vars
      @client.authorization = OauthClient.new(user_id).authorize
    end
  end
end
