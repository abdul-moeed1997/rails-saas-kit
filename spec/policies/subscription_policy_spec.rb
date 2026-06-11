require "rails_helper"

RSpec.describe SubscriptionPolicy, type: :policy do
  let(:account) { create(:account) }
  let(:subscription) { build(:subscription, account: account) }

  permissions :manage? do
    it "grants access to owners" do
      user = create(:user, account: account)
      expect(described_class).to permit(user, subscription)
    end

    it "denies access to admins" do
      user = create(:user, :admin, account: account)
      expect(described_class).not_to permit(user, subscription)
    end

    it "denies access to members" do
      user = create(:user, :member, account: account)
      expect(described_class).not_to permit(user, subscription)
    end
  end
end
