FactoryBot.define do
  factory :feature do
    sequence(:key) { |n| "feature_#{n}" }
    sequence(:name) { |n| "Feature #{n}" }
    description { "A test feature" }
  end
end
