# frozen_string_literal: true

# Users controller
class UsersController < ApplicationController
  def index
    outcome = CompaniesList.new(params[:filter]).call
    render json: { errors: outcome[:errors] }, status: 400 and return unless outcome[:success]

    render json: { data: outcome[:data], meta: {} }
  end

  def create
    user = User.create(user_params)
    render json: { data: user }
  end

  # TODO: Move them to google_calendar_controller etc.
  def authorize
    setup_client(@user.id)
    @user.integrations.create!(name: 'google_calendar', status: 'pending')
    redirect_to authorizer.get_authorization_url base_url: 'http://localhost:8080'
    # redirect_to oauth_callback_url(@companies.first)
  end

  def oauth_callback
    @integration = @user.integrations.find_by(name: 'google_calendar', status: 'pending')
    credentials = @authorizer.get_and_store_credentials_from_code(
      user_id: @user.id, code: params[:code], base_url: 'http://localhost:8080'
    )
    # TODO: add credentials to integrations or create a token table
    @integration.update!(status: 'active')
  rescue StandardError => e
    Rails.logger.info(e)
    @integration.update!(status: 'unauthorized')
  end

  def setup_calendar
    @user = User.find(params[:user_id])
    @user.sync_events!
  end

  private

  def user_params
    params.permit(:name, :email)
  end

  def setup_client(user_id)
    client_id = Google::Auth::ClientId.from_file('credentials.json')
    token_store = Google::Auth::Stores::FileTokenStore.new(file: 'token.yaml')
    @authorizer = Google::Auth::UserAuthorizer.new(
      client_id, Google::Apis::CalendarV3::AUTH_CALENDAR_EVENTS, token_store
    )
  end
end
