FactoryBot.define do
  factory :schedule_reminder do
    association :schedule
    minutes           { 10 }
    reminder_method   { :popup }
  end
end
