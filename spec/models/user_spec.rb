require "rails_helper"

RSpec.describe User, type: :model do
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
  end

  it "sends confirmation instructions when :confirmable is enabled",
     skip: "enable :confirmable on User and add confirmation columns before implementing" do
  end

  it "locks the account after failed sign-in attempts when :lockable is enabled",
     skip: "enable :lockable on User and add lockable columns before implementing" do
  end
end
