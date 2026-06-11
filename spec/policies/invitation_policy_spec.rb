require "rails_helper"

RSpec.describe InvitationPolicy, type: :policy do
  before { load_billing_catalog! }

  let(:account) { create(:account) }
  let(:invitation) { build(:invitation, account: account) }

  permissions :create? do
    before { create_pro_subscription(account) }

    it "grants access to owners" do
      user = create(:user, account: account)
      expect(described_class).to permit(user, invitation)
    end

    it "grants access to admins" do
      user = create(:user, :admin, account: account)
      expect(described_class).to permit(user, invitation)
    end

    it "denies access to members" do
      user = create(:user, :member, account: account)
      expect(described_class).not_to permit(user, invitation)
    end

    it "denies access when invitations are not on the plan" do
      ActsAsTenant.with_tenant(account) do
        account.subscription&.destroy!
        create(:subscription, account: account, price: free_price, status: "active")
      end

      user = create(:user, account: account)
      expect(described_class).not_to permit(user, invitation)
    end
  end

  permissions :destroy? do
    it "grants access to owners" do
      user = create(:user, account: account)
      expect(described_class).to permit(user, invitation)
    end

    it "grants access to admins" do
      user = create(:user, :admin, account: account)
      expect(described_class).to permit(user, invitation)
    end

    it "denies access to members" do
      user = create(:user, :member, account: account)
      expect(described_class).not_to permit(user, invitation)
    end
  end
end
