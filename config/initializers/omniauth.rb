# config/initializers/omniauth.rb
OmniAuth.config.allowed_request_methods = [:post, :get]

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           ENV.fetch('GOOGLE_CLIENT_ID', nil),
           ENV.fetch('GOOGLE_CLIENT_SECRET', nil),
           {
             scope: 'email,profile', # Simplified scope
             prompt: 'select_account',
             callback_path: '/auth/google_oauth2/callback',
             access_type: 'offline',
             redirect_uri: 'http://127.0.0.1:3000/auth/google_oauth2/callback'
           }
end

# Add this to handle CSRF protection
OmniAuth.config.silence_get_warning = true