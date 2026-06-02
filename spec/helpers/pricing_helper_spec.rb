require "rails_helper"

RSpec.describe PricingHelper, type: :helper do
  describe "#format_price_cents" do
    it "returns Free for zero" do
      expect(helper.format_price_cents(0)).to eq("Free")
    end

    it "formats dollar amounts" do
      expect(helper.format_price_cents(2900)).to eq("$29")
    end
  end

  describe "#pricing_amount_display_annual" do
    it "shows monthly equivalent and yearly subtext" do
      plan = create(:plan)
      month = create(:price, plan: plan, interval: "month", amount_cents: 2900)
      year = create(:price, plan: plan, interval: "year", amount_cents: 29_000)

      display = helper.pricing_amount_display_annual(month, year)

      expect(display[:amount]).to eq("$24.17")
      expect(display[:period]).to eq("/month")
      expect(display[:subtext]).to eq("Billed $290 yearly")
    end
  end

  describe "#annual_savings_percent" do
    it "calculates savings for annual vs monthly" do
      plan = create(:plan)
      create(:price, plan: plan, interval: "month", amount_cents: 2900)
      create(:price, plan: plan, interval: "year", amount_cents: 29_000)

      expect(helper.annual_savings_percent(plan)).to eq(17)
    end
  end
end
