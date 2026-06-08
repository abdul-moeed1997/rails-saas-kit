module Stripe
  class CheckoutSessionCreator
    class Error < StandardError; end

    def self.call(account:, plan:, interval:, success_url:, cancel_url:)
      new(account:, plan:, interval:, success_url:, cancel_url:).call
    end

    def initialize(account:, plan:, interval:, success_url:, cancel_url:)
      @account = account
      @plan = plan
      @interval = interval
      @success_url = success_url
      @cancel_url = cancel_url
    end

    def call
      raise Error, "Free plan does not require checkout" if @plan.slug == "free"

      price = @plan.price_for(@interval)
      raise Error, "Price not available for #{@interval} billing" unless price&.active?
      raise Error, "Stripe price not configured" if price.stripe_price_id.blank?

      customer = CustomerFinder.call(@account)

      session = ::Stripe::Checkout::Session.create(
        mode: "subscription",
        customer: customer.id,
        line_items: [ { price: price.stripe_price_id, quantity: 1 } ],
        subscription_data: {
          trial_period_days: StripeConfig.trial_period_days,
          metadata: {
            account_id: @account.id,
            price_id: price.id
          }
        },
        client_reference_id: @account.id.to_s,
        metadata: {
          account_id: @account.id,
          price_id: price.id
        },
        success_url: @success_url,
        cancel_url: @cancel_url
      )

      session.url
    end
  end
end
