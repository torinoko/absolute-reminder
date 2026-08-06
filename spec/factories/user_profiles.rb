FactoryBot.define do
  factory :user_profile do
    association :user
    provider      { 'google_oauth2' }
    uid           { Faker::Alphanumeric.alphanumeric(number: 10) }
    access_token  { Faker::Alphanumeric.alphanumeric(number: 40) }
    refresh_token { Faker::Alphanumeric.alphanumeric(number: 40) }
  end
end
