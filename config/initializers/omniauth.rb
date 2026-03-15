Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           ENV['GOOGLE_CLIENT_ID'],
           ENV['GOOGLE_CLIENT_SECRET'],
           scope: 'openid, profile, email, calendar.readonly',
           skip_jwt: true,
           prompt: 'consent',
           access_type: 'offline'
end
OmniAuth.config.allowed_request_methods = %i[get]
