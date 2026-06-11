require "rails_helper"

RSpec.describe InvitationPolicy, type: :policy do
  let(:account) { create(:account) }
  let(:invitation) { build(:invitation, account: account) }

  permissions :create?, :destroy? do
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
