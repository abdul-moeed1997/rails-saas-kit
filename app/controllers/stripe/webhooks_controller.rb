module Stripe
  class WebhooksController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      payload = request.body.read
      signature = request.env["HTTP_STRIPE_SIGNATURE"]
      webhook_secret = Rails.application.credentials.dig(:stripe, :webhook_secret)
      webhook_event = nil

      event = ::Stripe::Webhook.construct_event(payload, signature, webhook_secret)

      webhook_event = claim_event!(event)
      return head :ok if webhook_event.nil?

      WebhookProcessor.call(event)
      webhook_event.update!(status: "processed", processed_at: Time.current, error_message: nil)
      head :ok
    rescue ::Stripe::SignatureVerificationError
      head :bad_request
    rescue StandardError => e
      webhook_event&.update(status: "failed", error_message: e.message)
      raise e
    end

    private

    # Atomically claims the event for processing by inserting a "processing" record.
    # Returns nil if the event was already successfully processed (duplicate delivery).
    # Returns the existing record if it previously failed, allowing a retry.
    def claim_event!(event)
      existing = StripeWebhookEvent.find_by(stripe_event_id: event.id)

      if existing
        return nil unless existing.failed?

        existing.update!(status: "processing", error_message: nil)
        return existing
      end

      StripeWebhookEvent.create!(
        stripe_event_id: event.id,
        event_type: event.type,
        status: "processing"
      )
    rescue ActiveRecord::RecordNotUnique
      # Concurrent request beat us — check its status
      existing = StripeWebhookEvent.find_by!(stripe_event_id: event.id)
      existing.failed? ? existing.tap { |e| e.update!(status: "processing", error_message: nil) } : nil
    end
  end
end
