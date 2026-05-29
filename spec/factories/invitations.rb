FactoryBot.define do
  factory :invitation do
    account
    invited_by { association :user, account: account }
    sequence(:email) { |n| "invite#{n}@example.com" }
    expires_at { Invitation::EXPIRES_IN.from_now }

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :accepted do
      accepted_at { Time.current }
    end
  end
end
