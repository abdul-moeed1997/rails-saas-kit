FactoryBot.define do
  factory :user do
    account
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123456" }
    password_confirmation { "password123456" }

    role do
      if account&.persisted? && account.users.where(role: :owner).exists?
        :member
      else
        :owner
      end
    end

    trait :owner do
      role { :owner }
    end

    trait :admin do
      role { :admin }
    end

    trait :member do
      role { :member }
    end

    trait :platform_admin do
      platform_admin { true }
    end
  end
end
