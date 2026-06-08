module Subscriptions
  class ProvisionFree
    def self.call(account)
      new(account).call
    end

    def initialize(account)
      @account = account
    end

    def call
      return @account.subscription if @account.subscription.present?

      plan = Plan.find_by_slug!("free")
      price = plan.price_for("month")
      raise ActiveRecord::RecordNotFound, "Free plan price not found" unless price

      ActsAsTenant.with_tenant(@account) do
        @account.create_subscription!(price: price, status: "active")
      end
    end

    def self.reset_to_free!(subscription)
      new(subscription.account).reset_to_free!(subscription)
    end

    def reset_to_free!(subscription)
      plan = Plan.find_by_slug!("free")
      price = plan.price_for("month")
      raise ActiveRecord::RecordNotFound, "Free plan price not found" unless price

      subscription.update!(
        price: price,
        status: "active",
        stripe_subscription_id: nil,
        current_period_start: nil,
        current_period_end: nil,
        trial_ends_at: nil,
        cancel_at_period_end: false,
        canceled_at: nil
      )
    end
  end
end
