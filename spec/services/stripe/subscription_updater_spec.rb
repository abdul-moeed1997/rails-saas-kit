require "rails_helper"

RSpec.describe Stripe::SubscriptionUpdater do
  before { load_billing_catalog! }

  describe ".call" do
    it "updates a local subscription" do
      account = create(:account)
      ActsAsTenant.with_tenant(account) do
        create(:subscription, account: account, price: free_price, status: "active")
      end
      subscription = account.reload.subscription

      described_class.call(subscription:, price: pro_monthly_price, status: "active")

      expect(subscription.reload.plan.slug).to eq("pro")
      expect(subscription.status).to eq("active")
    end

    it "updates a Stripe-managed subscription" do
      account = create(:account)
      pro_monthly_price.update!(stripe_price_id: "price_pro_month")
      business_plan = Plan.find_by_slug!("business")
      business_price = business_plan.price_for("month")
      business_price.update!(stripe_price_id: "price_business_month")

      ActsAsTenant.with_tenant(account) do
        create(:subscription, :with_stripe_ids, account: account, price: pro_monthly_price, status: "active")
      end
      subscription = account.reload.subscription

      stripe_sub = Stripe::Subscription.construct_from(
        id: subscription.stripe_subscription_id,
        status: "active",
        customer: subscription.stripe_customer_id,
        cancel_at_period_end: false,
        items: { data: [ { id: "si_123", price: { id: business_price.stripe_price_id } } ] }
      )

      allow(Stripe::Subscription).to receive(:retrieve).and_return(stripe_sub)
      allow(Stripe::Subscription).to receive(:update).and_return(stripe_sub)

      described_class.call(subscription:, price: business_price, status: "active")

      expect(subscription.reload.price).to eq(business_price)
    end
  end
end
