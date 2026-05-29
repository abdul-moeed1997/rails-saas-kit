require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it "belongs to an account" do
      account = create(:account)
      user = create(:user, account: account)
      expect(user.account).to eq(account)
    end

    it "scopes queries to the current tenant" do
      acme = create(:account, subdomain: "acme")
      other = create(:account, subdomain: "other")
      acme_user = create(:user, account: acme)
      create(:user, account: other)

      ActsAsTenant.with_tenant(acme) do
        expect(User.all).to contain_exactly(acme_user)
      end
    end
  end

  describe "validations (Devise :validatable)" do
    it "has a valid factory" do
      expect(build(:user)).to be_valid
    end

    it "requires an email" do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to be_present
    end

    it "requires a unique email" do
      create(:user, email: "taken@example.com")
      duplicate = build(:user, email: "taken@example.com")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to be_present
    end

    it "requires a password" do
      user = build(:user, password: nil, password_confirmation: nil)
      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present
    end

    it "requires an account on update when none is set" do
      user = create(:user)
      ActsAsTenant.with_mutable_tenant { user.account = nil }
      expect(user).not_to be_valid
      expect(user.errors[:account]).to be_present
    end

    it "requires an account on create when none is provided" do
      user = build(:user, account: nil)
      expect(user).not_to be_valid
      expect(user.errors[:account]).to be_present
    end

    it "can create an organization through nested attributes" do
      user = build(
        :user,
        account: nil,
        account_attributes: { name: "Acme Corp", subdomain: "acme" }
      )
      expect(user).to be_valid
      expect(user.account.name).to eq("Acme Corp")
      expect(user.account.subdomain).to eq("acme")
    end
  end

  it "sends confirmation instructions when :confirmable is enabled",
     skip: "enable :confirmable on User and add confirmation columns before implementing" do
  end

  it "locks the account after failed sign-in attempts when :lockable is enabled",
     skip: "enable :lockable on User and add lockable columns before implementing" do
  end
end
