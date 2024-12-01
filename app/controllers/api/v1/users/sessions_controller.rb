module Api
  module V1
    module Users
      class SessionsController < Devise::SessionsController
        include ActionController::MimeResponds
        skip_before_action :verify_signed_out_user

        respond_to :json

        # POST /api/v1/login
        def create
          user = User.find_by(email: sign_in_params[:email])

          if user&.valid_password?(sign_in_params[:password])
            sign_in(user)
            render json: {
              status: { code: 200, message: "Logged in successfully." },
              data: serialize_user(user),
              token: request.env["warden-jwt_auth.token"]
            }
          else
            render json: {
              status: {
                code: 401,
                message: "Invalid email or password."
              }
            }, status: :unauthorized
          end
        end

        private

        def sign_in_params
          params.require(:user).permit(:email, :password)
        end

        def serialize_user(user)
          {
            id: user.id,
            email: user.email,
            created_at: user.created_at,
            created_date: user.created_at.strftime("%d/%m/%Y")
          }
        end

        def respond_to_on_destroy
          head :no_content
        end
      end
    end
  end
end
