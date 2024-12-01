module Api
  module V1
    module Users
      class RegistrationsController < Devise::RegistrationsController
        include ActionController::MimeResponds
        
        respond_to :json
        
        def create
          build_resource(sign_up_params)
          resource.save
          render_resource(resource)
        end

        private

        def sign_up_params
          params.require(:user).permit(:email, :password, :username)
        end

        def render_resource(resource)
          if resource.persisted?
            render json: {
              status: { code: 200, message: 'Signed up successfully.' },
              data: serialize_user(resource)
            }
          else
            render json: {
              status: { 
                message: "User couldn't be created successfully.",
                errors: resource.errors.full_messages 
              }
            }, status: :unprocessable_entity
          end
        end

        def serialize_user(user)
          {
            id: user.id,
            email: user.email,
            created_at: user.created_at,
            created_date: user.created_at.strftime('%d/%m/%Y')
          }
        end
      end
    end
  end
end