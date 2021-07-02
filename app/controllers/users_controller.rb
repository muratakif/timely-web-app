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

  def authorize; end

  def setup_calendar
    @user = User.find(params[:user_id])
    @user.sync_events!
  end

  private

  def user_params
    params.permit(:name, :email)
  end
end
