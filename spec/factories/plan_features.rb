FactoryBot.define do
  factory :plan_feature do
    plan
    feature
    enabled { true }
    limit_value { nil }
  end
end
