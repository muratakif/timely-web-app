# frozen_string_literal: true

require "googleauth/stores/file_token_store"

module Integrations::GoogleCalendar
  class OauthClient
    CONFIG_KEY = 'g_calendar'
    AUTH_URI = 'https://accounts.google.com/o/oauth2/oauth'

    # TODO: Move to env vars
    OOB_URI = "http://localhost:8080".freeze
    CREDENTIALS_PATH = "credentials.json".freeze
    TOKEN_PATH = "token.yaml".freeze
    SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY
    
    # TODO: How about having a Permission table to deal with scopes?
    def initialize(user_id, scope = nil)
      @user_id = user_id
      @config = config
      @scope = scope
    end

    def authorize
      client_id = Google::Auth::ClientId.from_file CREDENTIALS_PATH
      token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH
      authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
      credentials = authorizer.get_credentials @user_id
      if credentials.nil?
        url = authorizer.get_authorization_url base_url: OOB_URI
        puts "Open the following URL in the browser and enter the " \
             "resulting code after authorization:\n" + url
        code = gets
        credentials = authorizer.get_and_store_credentials_from_code(
          user_id: @user_id, code: code, base_url: OOB_URI
        )
      end
      credentials
    end

    private

    # def connect
    #   result = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request_params) }
    #   parsed_response = JSON.parse(result.body)
    #   parsed_response['code']
    # end

    def config
    #   Rails.application.secrets.integrations[CONFIG_KEY]
    end

    def request_params
    #   request = Net::HTTP::Get.new(uri)
    #   request['client_id'] = @config['client_id']
    #   request['client_secret'] = @config['client_secret']
    #   request['redirect_uri'] = Rails.application.routes.url_helpers.oauth_authorization_url
    #   request['scope'] = @scope || @config['scope']
    #   request
    end
  end
end