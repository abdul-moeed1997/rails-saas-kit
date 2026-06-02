require "rails_helper"

RSpec.describe Plan, type: :model do
  describe "associations" do
    it "has many prices" do
      plan = create(:plan)
      price = create(:price, plan: plan)
      expect(plan.prices).to contain_exactly(price)
    end

    it "has many plan_features and features" do
      plan = create(:plan)
      feature = create(:feature)
      plan_feature = create(:plan_feature, plan: plan, feature: feature)
      expect(plan.plan_features).to contain_exactly(plan_feature)
      expect(plan.features).to contain_exactly(feature)
    end
  end

  describe "validations" do
    it "has a valid factory" do
      expect(build(:plan)).to be_valid
    end

    it "requires a unique slug" do
      create(:plan, slug: "pro")
      duplicate = build(:plan, slug: "pro")
      expect(duplicate).not_to be_valid
    end

    it "requires slug format" do
      plan = build(:plan, slug: "Pro Plan")
      expect(plan).not_to be_valid
    end
  end

  describe "entitlements" do
    it "returns feature_enabled? and feature_limit" do
      plan = create(:plan)
      feature = create(:feature, key: "seats")
      create(:plan_feature, plan: plan, feature: feature, enabled: true, limit_value: 5)

      expect(plan.feature_enabled?(:seats)).to be(true)
      expect(plan.feature_limit(:seats)).to eq(5)
      expect(plan.feature_enabled?(:sso)).to be(false)
    end
  end
end
