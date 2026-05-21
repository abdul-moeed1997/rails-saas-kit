FactoryBot.define do
  factory :account do
    sequence(:name) { |n| "Account #{n}" }
    sequence(:subdomain) { |n| "account-#{n}" }
  end
end
