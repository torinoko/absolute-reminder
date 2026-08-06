FactoryBot.define do
  factory :schedule do
    association :user
    google_event_id { Faker::Alphanumeric.alphanumeric(number: 26) }
    summary         { "テスト予定！" }
    start_at        { 2.hours.from_now }
    end_at          { 3.hours.from_now }
  end
end
