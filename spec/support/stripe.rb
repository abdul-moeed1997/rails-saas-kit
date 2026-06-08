module StripeHelpers
  def stripe_credentials
    {
      publishable_key: "pk_test_example",
      secret_key: "sk_test_example",
      webhook_secret: "whsec_test_secret"
    }
  end

  def stub_stripe_credentials
    allow(Rails.application.credentials).to receive(:dig).and_call_original
    allow(Rails.application.credentials).to receive(:dig).with(:stripe, :secret_key).and_return(stripe_credentials[:secret_key])
    allow(Rails.application.credentials).to receive(:dig).with(:stripe, :publishable_key).and_return(stripe_credentials[:publishable_key])
    allow(Rails.application.credentials).to receive(:dig).with(:stripe, :webhook_secret).and_return(stripe_credentials[:webhook_secret])
  end

  def build_stripe_subscription_object(attrs = {})
    period_start = Time.current.to_i
    period_end = 1.month.from_now.to_i
    defaults = {
      id: "sub_123",
      customer: "cus_123",
      status: "active",
      trial_end: nil,
      cancel_at_period_end: false,
      canceled_at: nil,
      metadata: {},
      items: {
        data: [
          {
            price: { id: "price_pro_month" },
            current_period_start: period_start,
            current_period_end: period_end
          }
        ]
      }
    }
    Stripe::Subscription.construct_from(defaults.deep_merge(attrs))
  end

  def build_stripe_event(type:, object:)
    Stripe::Event.construct_from(
      id: "evt_#{SecureRandom.hex(8)}",
      type: type,
      data: { object: object }
    )
  end

  def signed_webhook_payload(event_json)
    payload = event_json.to_json
    timestamp = Time.now
    signature = Stripe::Webhook::Signature.compute_signature(
      timestamp,
      payload,
      stripe_credentials[:webhook_secret]
    )

    {
      payload: payload,
      header: "t=#{timestamp.to_i},v1=#{signature}"
    }
  end
end

RSpec.configure do |config|
  config.include StripeHelpers

  config.before do
    stub_stripe_credentials
  end
end
