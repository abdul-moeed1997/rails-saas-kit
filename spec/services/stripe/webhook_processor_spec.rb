require "rails_helper"

RSpec.describe Stripe::WebhookProcessor do
  before { load_billing_catalog! }

  let(:account) { create(:account) }
  let(:price) { pro_monthly_price.tap { |p| p.update!(stripe_price_id: "price_pro_month") } }
  let!(:subscription) do
    ActsAsTenant.with_tenant(account) do
      create(:subscription,
        account: account,
        price: free_price,
        status: "active",
        stripe_customer_id: "cus_123",
        stripe_subscription_id: "sub_123")
    end
  end

  describe "customer.subscription.updated" do
    it "syncs the subscription" do
      stripe_subscription = build_stripe_subscription_object(
        id: "sub_123",
        status: "trialing",
        trial_end: 14.days.from_now.to_i,
        items: { data: [ { price: { id: price.stripe_price_id } } ] }
      )
      event = build_stripe_event(type: "customer.subscription.updated", object: stripe_subscription)

      described_class.call(event)

      expect(subscription.reload).to have_attributes(status: "trialing", price_id: price.id)
    end
  end

  describe "customer.subscription.deleted" do
    it "resets the subscription to the free plan" do
      stripe_subscription = build_stripe_subscription_object(id: "sub_123")
      event = build_stripe_event(type: "customer.subscription.deleted", object: stripe_subscription)

      described_class.call(event)

      expect(subscription.reload).to have_attributes(
        price_id: free_price.id,
        status: "active",
        stripe_subscription_id: nil
      )
    end
  end

  describe "invoice.payment_failed" do
    it "marks the subscription past due" do
      invoice = Stripe::Invoice.construct_from(subscription: "sub_123")
      event = build_stripe_event(type: "invoice.payment_failed", object: invoice)

      described_class.call(event)

      expect(subscription.reload.status).to eq("past_due")
    end
  end

  describe "invoice.paid" do
    it "reactivates a past due subscription" do
      subscription.update!(status: "past_due")
      invoice = Stripe::Invoice.construct_from(subscription: "sub_123")
      event = build_stripe_event(type: "invoice.paid", object: invoice)

      described_class.call(event)

      expect(subscription.reload.status).to eq("active")
    end
  end
end
