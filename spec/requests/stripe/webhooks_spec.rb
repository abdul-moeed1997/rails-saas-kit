require "rails_helper"

RSpec.describe "Stripe webhooks", type: :request do
  let(:event) do
    build_stripe_event(
      type: "invoice.paid",
      object: Stripe::Invoice.construct_from(subscription: "sub_missing")
    )
  end

  it "returns ok for a valid signed event" do
    signed = signed_webhook_payload(event)

    expect do
      post stripe_webhooks_path,
           params: signed[:payload],
           headers: { "Stripe-Signature" => signed[:header], "CONTENT_TYPE" => "application/json" }
    end.to change(StripeWebhookEvent, :count).by(1)

    expect(response).to have_http_status(:ok)
  end

  it "returns bad request for an invalid signature" do
    post stripe_webhooks_path,
         params: event.to_json,
         headers: { "Stripe-Signature" => "invalid", "CONTENT_TYPE" => "application/json" }

    expect(response).to have_http_status(:bad_request)
  end

  it "retries failed events on redelivery" do
    signed = signed_webhook_payload(event)

    post stripe_webhooks_path,
         params: signed[:payload],
         headers: { "Stripe-Signature" => signed[:header], "CONTENT_TYPE" => "application/json" }

    webhook_event = StripeWebhookEvent.last
    webhook_event.update!(status: "failed", error_message: "temporary error")

    expect do
      post stripe_webhooks_path,
           params: signed[:payload],
           headers: { "Stripe-Signature" => signed[:header], "CONTENT_TYPE" => "application/json" }
    end.not_to change(StripeWebhookEvent, :count)

    expect(webhook_event.reload.status).to eq("processed")
    expect(response).to have_http_status(:ok)
  end

  it "deduplicates successfully processed events by stripe event id" do
    signed = signed_webhook_payload(event)

    post stripe_webhooks_path,
         params: signed[:payload],
         headers: { "Stripe-Signature" => signed[:header], "CONTENT_TYPE" => "application/json" }

    expect do
      post stripe_webhooks_path,
           params: signed[:payload],
           headers: { "Stripe-Signature" => signed[:header], "CONTENT_TYPE" => "application/json" }
    end.not_to change(StripeWebhookEvent, :count)

    expect(response).to have_http_status(:ok)
  end
end
