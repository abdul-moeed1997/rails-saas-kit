FactoryBot.define do
  factory :plan do
    sequence(:name) { |n| "Plan #{n}" }
    sequence(:slug) { |n| "plan-#{n}" }
    description { "A test plan" }
    status { "active" }
    highlighted { false }
    position { 0 }

    trait :highlighted do
      highlighted { true }
    end

    trait :with_prices do
      after(:create) do |plan|
        create(:price, plan: plan, interval: "month", amount_cents: 2900)
        create(:price, plan: plan, interval: "year", amount_cents: 29_000)
      end
    end
  end
end
