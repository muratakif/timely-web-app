# frozen_string_literal: true

class UsersController < ApplicationController
	def index
		outcome = CompaniesList.new(params[:filter]).call

		unless outcome[:success]
			render json: { errors: outcome[:errors] }, status: 400 and return
		end

		render json: { data: outcome[:data], meta: {} }
	end

	def create
		user = User.create(user_params)

		render json: { data: user }
	end

	def authorize
	end

	def setup_calendar
		@user = User.find(params[:user_id])
		@user.sync_events!
	end

	private

	def user_params
		params.permit(:name, :email)
	end
end