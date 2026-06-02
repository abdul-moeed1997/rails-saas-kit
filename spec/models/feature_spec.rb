require "rails_helper"

RSpec.describe Feature, type: :model do
  describe "validations" do
    it "has a valid factory" do
      expect(build(:feature)).to be_valid
    end

    it "requires a unique key" do
      create(:feature, key: "seats")
      duplicate = build(:feature, key: "seats")
      expect(duplicate).not_to be_valid
    end
  end
end
