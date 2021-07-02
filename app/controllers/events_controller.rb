# frozen_string_literal: true

class UsersController < ApplicationController
  def authenticate
    res = Events::Authenticate.new(params[:user_id], params[:token]).call

    render json: { errors: res[:errors] }, status: 400 and return unless res[:success]

    render json: { data: res[:data], meta: {} }
  end
end
