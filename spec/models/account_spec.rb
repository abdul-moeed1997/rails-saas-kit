require "rails_helper"

RSpec.describe Account, type: :model do
  describe "associations" do
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
end
