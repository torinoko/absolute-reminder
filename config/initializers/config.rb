# frozen_string_literal: true

module Config
  GOOGLE_CLIENT_ID = Rails.application.credentials.google[:client_id]
  GOOGLE_CLIENT_SECRET = Rails.application.credentials.google[:client_secret]
  APPLICATION_NAME = 'Habita'
end
