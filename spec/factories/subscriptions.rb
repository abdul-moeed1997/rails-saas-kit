FactoryBot.define do
  factory :subscription do
    account
    price
    status { "active" }

    trait :with_stripe_ids do
      stripe_customer_id { "cus_#{SecureRandom.hex(6)}" }
      stripe_subscription_id { "sub_#{SecureRandom.hex(6)}" }
    end

    trait :trialing do
      status { "trialing" }
      trial_ends_at { 14.days.from_now }
    end

    trait :past_due do
      status { "past_due" }
      stripe_customer_id { "cus_#{SecureRandom.hex(6)}" }
      stripe_subscription_id { "sub_#{SecureRandom.hex(6)}" }
    end
  end
end
