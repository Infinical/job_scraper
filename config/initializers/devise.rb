Devise.setup do |config|
  # Add the following lines
  config.navigational_formats = []
  config.parent_controller = "ActionController::API"

  # JWT Configuration
  config.jwt do |jwt|
    jwt.secret = ENV["DEVISE_JWT_SECRET_KEY"]
    jwt.dispatch_requests = [
      [ "POST", %r{^/api/v1/login$} ]
    ]
    jwt.revocation_requests = [
      [ "DELETE", %r{^/api/v1/logout$} ]
    ]
    jwt.expiration_time = 1.day.to_i
  end
end
