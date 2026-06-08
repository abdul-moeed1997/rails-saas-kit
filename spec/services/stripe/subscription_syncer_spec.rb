require "rails_helper"

RSpec.describe Stripe::SubscriptionSyncer do
  before { load_billing_catalog! }

  let(:account) { create(:account) }
  let(:price) { pro_monthly_price.tap { |p| p.update!(stripe_price_id: "price_pro_month") } }

  before do
    ActsAsTenant.with_tenant(account) do
      create(:subscription, account: account, price: free_price, status: "active")
    end
  end

  it "syncs when stripe price is a string id" do
    stripe_subscription = build_stripe_subscription_object(
      metadata: { "account_id" => account.id.to_s },
      items: { data: [ { price: price.stripe_price_id } ] }
    )

    result = described_class.call(stripe_subscription:, account:)

    expect(result.price_id).to eq(price.id)
  end

  it "syncs stripe subscription fields onto the local subscription" do
    stripe_subscription = build_stripe_subscription_object(
      metadata: { "account_id" => account.id.to_s },
      items: {
        data: [
          {
            price: { id: price.stripe_price_id },
            current_period_start: Time.current.to_i,
            current_period_end: 1.month.from_now.to_i
          }
        ]
      }
    )

    result = described_class.call(stripe_subscription:, account:)

    expect(result).to have_attributes(
      stripe_subscription_id: "sub_123",
      stripe_customer_id: "cus_123",
      status: "active",
      price_id: price.id
    )
    expect(result.current_period_end).to be_present
  end
end
