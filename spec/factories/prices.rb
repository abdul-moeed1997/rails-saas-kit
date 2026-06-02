FactoryBot.define do
  factory :price do
    plan
    amount_cents { 2900 }
    currency { "usd" }
    interval { "month" }
    active { true }
  end
end
