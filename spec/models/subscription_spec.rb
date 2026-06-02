require "rails_helper"

RSpec.describe Subscription, type: :model do
  describe "associations" do
    it "belongs to account and price" do
      subscription = create(:subscription)
      expect(subscription.account).to be_present
      expect(subscription.price).to be_present
      expect(subscription.plan).to eq(subscription.price.plan)
    end

    it "scopes queries to the current tenant" do
      acme = create(:account, subdomain: "acme")
      other = create(:account, subdomain: "other")
      acme_subscription = create(:subscription, account: acme)
      create(:subscription, account: other)

      ActsAsTenant.with_tenant(acme) do
        expect(Subscription.all).to contain_exactly(acme_subscription)
      end
    end
  end

  describe ".find_by_stripe_subscription_id!" do
    it "finds the subscription without a current tenant" do
      subscription = create(:subscription, stripe_subscription_id: "sub_123")

      found = ActsAsTenant.with_tenant(create(:account)) do
        Subscription.find_by_stripe_subscription_id!("sub_123")
      end

      expect(found).to eq(subscription)
    end
  end

  describe "validations" do
    it "has a valid factory" do
      expect(build(:subscription)).to be_valid
    end

    it "requires an account on create when none is provided" do
      subscription = build(:subscription, account: nil)
      expect(subscription).not_to be_valid
      expect(subscription.errors[:account]).to be_present
    end
  end

  describe "entitlements" do
    it "delegates feature checks to plan" do
      plan = create(:plan)
      feature = create(:feature, key: "sso")
      create(:plan_feature, plan: plan, feature: feature, enabled: true)
      price = create(:price, plan: plan)
      subscription = create(:subscription, price: price)

      expect(subscription.feature_enabled?(:sso)).to be(true)
    end
  end

  describe "#active?" do
    it "is true for trialing and active statuses" do
      subscription = build(:subscription, status: "trialing")
      expect(subscription).to be_active

      subscription.status = "canceled"
      expect(subscription).not_to be_active
    end
  end
end
