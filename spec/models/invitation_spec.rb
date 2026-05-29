require "rails_helper"

RSpec.describe Invitation, type: :model do
  describe "validations" do
    it "has a valid factory" do
      expect(build(:invitation)).to be_valid
    end

    it "requires an email" do
      invitation = build(:invitation, email: nil)
      expect(invitation).not_to be_valid
    end

    it "does not allow inviting an existing team member" do
      account = create(:account)
      create(:user, account: account, email: "member@example.com")

      invitation = build(:invitation, account: account, email: "member@example.com")
      expect(invitation).not_to be_valid
      expect(invitation.errors[:email]).to include("is already on your team")
    end

    it "does not allow inviting an email that already has a user account" do
      create(:user, email: "taken@example.com")
      invitation = build(:invitation, email: "taken@example.com")

      expect(invitation).not_to be_valid
      expect(invitation.errors[:email]).to include("already has an account—ask them to sign in instead")
    end

    it "does not allow duplicate pending invitations for the same email" do
      account = create(:account)
      create(:invitation, account: account, email: "pending@example.com")

      duplicate = build(:invitation, account: account, email: "pending@example.com")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to include("already has a pending invitation")
    end
  end

  describe "#pending?" do
    it "is true for a new invitation" do
      expect(build(:invitation)).to be_pending
    end

    it "is false when accepted" do
      expect(build(:invitation, :accepted)).not_to be_pending
    end

    it "is false when expired" do
      expect(build(:invitation, :expired)).not_to be_pending
    end
  end
end
