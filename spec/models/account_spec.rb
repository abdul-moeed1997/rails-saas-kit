require "rails_helper"

RSpec.describe Account, type: :model do
  describe "associations" do
    it "has one subscription" do
      account = create(:account)
      subscription = create(:subscription, account: account)
      expect(account.subscription).to eq(subscription)
    end

    it "has many users" do
      account = create(:account)
      first_user = create(:user, account: account)
      second_user = create(:user, account: account)
      expect(account.users).to contain_exactly(first_user, second_user)
    end

    it "destroys users when the account is destroyed" do
      account = create(:account)
      create(:user, account: account)
      expect { account.destroy }.to change(User, :count).by(-1)
    end
  end

  describe "validations" do
    it "has a valid factory" do
      expect(build(:account)).to be_valid
    end

    it "requires a name" do
      account = build(:account, name: nil)
      expect(account).not_to be_valid
      expect(account.errors[:name]).to be_present
    end

    it "requires a subdomain" do
      account = build(:account, subdomain: nil)
      expect(account).not_to be_valid
      expect(account.errors[:subdomain]).to be_present
    end

    it "requires a unique subdomain" do
      create(:account, subdomain: "acme")
      duplicate = build(:account, subdomain: "acme")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:subdomain]).to be_present
    end
  end

  describe "entitlements" do
    it "delegates feature checks through subscription" do
      account = create(:account)
      plan = create(:plan)
      feature = create(:feature, key: "invitations")
      create(:plan_feature, plan: plan, feature: feature, enabled: true)
      price = create(:price, plan: plan)
      create(:subscription, account: account, price: price)

      expect(account.feature_enabled?(:invitations)).to be(true)
      expect(account.current_plan).to eq(plan)
    end

    it "returns false when there is no subscription" do
      account = create(:account)
      expect(account.feature_enabled?(:invitations)).to be(false)
    end
  end
end
