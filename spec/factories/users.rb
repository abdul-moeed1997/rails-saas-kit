FactoryBot.define do
  factory :user do
    account
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123456" }
    password_confirmation { "password123456" }
  end
end
