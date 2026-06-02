FactoryBot.define do
  factory :subscription do
    account
    price
    status { "active" }
  end
end
