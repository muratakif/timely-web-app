# frozen_string_literal: true

module Events
  # Service for authenticating users to Google Calendar API
  class Authenticate < BaseService
    def initialize(user_id, token)
      @user_id = user_id
      @token = token
      @errors = []
    end

    def call
      validate!
      authenticate_gcalendar
      create_event
    end

    private

    def validate!
      # ....
    end

    def authenticate_gcalendar
      # ....
    end

    def create_event
      # ....
    end
  end
end
