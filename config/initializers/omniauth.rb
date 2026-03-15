Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           Config::GOOGLE_CLIENT_ID,
           Config::GOOGLE_CLIENT_SECRET,
           scope: 'openid, profile, email, calendar.readonly',
           skip_jwt: true,
           prompt: 'consent',
           access_type: 'offline'
end
OmniAuth.config.allowed_request_methods = %i[get]
