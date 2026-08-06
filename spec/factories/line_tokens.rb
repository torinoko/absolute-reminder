FactoryBot.define do
  factory :line_token do
    uid        { Faker::Alphanumeric.alphanumeric(number: 33) }
    token      { SecureRandom.urlsafe_base64 }
    expires_at { 1.hour.from_now }
  end
end
