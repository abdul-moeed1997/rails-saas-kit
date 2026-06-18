# frozen_string_literal: true

module Stripe
  class SubscriptionUpdater
    class Error < StandardError; end

    def self.call(subscription:, price:, status: nil)
      new(subscription:, price:, status:).call
    end

    def initialize(subscription:, price:, status: nil)
      @subscription = subscription
      @price = price
      @status = status
    end

    def call
      if @subscription.stripe_managed?
        update_stripe_subscription!
      else
        update_local_subscription!
      end

      @subscription
    end

    private

    def update_stripe_subscription!
      raise Error, I18n.t("services.stripe.subscription_updater.stripe_price_missing") if @price.stripe_price_id.blank?

      stripe_subscription = ::Stripe::Subscription.retrieve(@subscription.stripe_subscription_id)
      item_id = stripe_subscription.items.data.first.id

      stripe_subscription = ::Stripe::Subscription.update(
        @subscription.stripe_subscription_id,
        items: [ { id: item_id, price: @price.stripe_price_id } ],
        metadata: { account_id: @subscription.account_id, price_id: @price.id }
      )

      ActsAsTenant.with_tenant(@subscription.account) do
        @subscription.sync_from_stripe!(stripe_subscription)
        @subscription.update!(status: @status) if @status.present?
      end
    end

    def update_local_subscription!
      ActsAsTenant.with_tenant(@subscription.account) do
        attrs = { price: @price }
        attrs[:status] = @status if @status.present?
        @subscription.update!(attrs)
      end
    end
  end
end
