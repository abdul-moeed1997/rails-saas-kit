module Stripe
  class SubscriptionSyncer
    def self.call(stripe_subscription:, account: nil)
      new(stripe_subscription:, account:).call
    end

    def initialize(stripe_subscription:, account: nil)
      @stripe_subscription = stripe_subscription
      @account = account
    end

    def call
      ActsAsTenant.without_tenant do
        subscription = find_subscription
        raise ActiveRecord::RecordNotFound, "Subscription not found for Stripe sync" unless subscription

        ActsAsTenant.with_tenant(subscription.account) do
          subscription.sync_from_stripe!(@stripe_subscription)
        end

        subscription
      end
    end

    private

    def find_subscription
      if @stripe_subscription.id.present?
        ::Subscription.find_by(stripe_subscription_id: @stripe_subscription.id) ||
          find_by_account&.tap { |sub| sub.update!(stripe_subscription_id: @stripe_subscription.id) }
      else
        find_by_account
      end
    end

    def find_by_account
      account = @account || account_from_metadata
      return unless account

      account.subscription || account.create_subscription!(price: free_price, status: "active")
    end

    def account_from_metadata
      account_id = @stripe_subscription.metadata&.account_id ||
        @stripe_subscription.metadata&.[]("account_id")
      ::Account.find_by(id: account_id) if account_id.present?
    end

    def free_price
      plan = ::Plan.find_by_slug!("free")
      plan.price_for("month") || raise(ActiveRecord::RecordNotFound, "Free plan price not found")
    end
  end
end
