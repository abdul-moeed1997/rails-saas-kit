require "rails_helper"

RSpec.describe Stripe::CatalogSyncer do
  before { load_billing_catalog! }

  describe ".sync_plan!" do
    it "creates a Stripe product for paid plans" do
      plan = create(:plan, slug: "enterprise", name: "Enterprise")

      allow(Stripe::Product).to receive(:create).and_return(
        Stripe::Product.construct_from(id: "prod_ent")
      )

      result = described_class.sync_plan!(plan)

      expect(result.success?).to be(true)
      expect(plan.reload.stripe_product_id).to eq("prod_ent")
    end

    it "skips Stripe for the free plan" do
      plan = Plan.find_by_slug!("free")

      expect(Stripe::Product).not_to receive(:create)
      result = described_class.sync_plan!(plan)
      expect(result.success?).to be(true)
    end

    it "updates an existing Stripe product" do
      plan = create(:plan, slug: "enterprise", name: "Enterprise", stripe_product_id: "prod_ent")

      expect(Stripe::Product).to receive(:update).with(
        "prod_ent",
        hash_including(name: "Enterprise Plus")
      )

      plan.update!(name: "Enterprise Plus")
      result = described_class.sync_plan!(plan)
      expect(result.success?).to be(true)
    end
  end

  describe ".sync_price!" do
    it "creates a Stripe price" do
      plan = create(:plan, slug: "enterprise", stripe_product_id: "prod_ent")
      price = create(:price, plan: plan, amount_cents: 4900, interval: "month")

      allow(Stripe::Product).to receive(:update)
      allow(Stripe::Price).to receive(:create).and_return(
        Stripe::Price.construct_from(id: "price_ent_month")
      )

      result = described_class.sync_price!(price)

      expect(result.success?).to be(true)
      expect(price.reload.stripe_price_id).to eq("price_ent_month")
    end
  end
end
