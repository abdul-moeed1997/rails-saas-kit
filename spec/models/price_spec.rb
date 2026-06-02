require "rails_helper"

RSpec.describe Price, type: :model do
  describe "associations" do
    it "belongs to a plan" do
      plan = create(:plan)
      price = create(:price, plan: plan)
      expect(price.plan).to eq(plan)
    end
  end

  describe "validations" do
    it "has a valid factory" do
      expect(build(:price)).to be_valid
    end

    it "requires a unique interval per plan" do
      plan = create(:plan)
      create(:price, plan: plan, interval: "month")
      duplicate = build(:price, plan: plan, interval: "month")
      expect(duplicate).not_to be_valid
    end
  end
end
