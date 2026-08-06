FactoryBot.define do
  factory :user do
    name  { Faker::Name.unique.name }
    email { Faker::Internet.unique.email }
  end
end
