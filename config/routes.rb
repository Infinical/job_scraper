require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users
  # Sidekiq Web UI
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  # API routes
  namespace :api do
    namespace :v1 do
      devise_for :users,
      controllers: {
        sessions: "api/v1/users/sessions",
        registrations: "api/v1/users/registrations"
      },
      path: "",
      path_names: {
        sign_in: "login",
        sign_out: "logout",
        registration: "signup"
      }


      authenticate :user do
        resources :job_preferences
        # Add your protected routes here
      end
    end
  end
end
