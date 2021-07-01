class UsersController < ApplicationController
	def authenticate
		res = Events::Authenticate.new(params[:user_id], params[:token]).call

		unless res[:success]
			render json: { errors: res[:errors] }, status: 400 and return
		end

		render json: { data: res[:data], meta: {} }
	end
end
