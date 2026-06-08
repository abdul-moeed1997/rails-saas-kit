module Stripe
  class CustomerFinder
    def self.call(account)
      new(account).call
    end

    def initialize(account)
      @account = account
    end

    def call
      subscription = @account.subscription
      return retrieve_existing(subscription.stripe_customer_id) if subscription&.stripe_customer_id.present?

      customer = ::Stripe::Customer.create(
        email: @account.users.order(:created_at).first&.email,
        name: @account.name,
        metadata: { account_id: @account.id }
      )

      ActsAsTenant.with_tenant(@account) do
        subscription ||= @account.build_subscription(price: free_price, status: "active")
        subscription.stripe_customer_id = customer.id
        subscription.save!
      end

      customer
    end

    private

    def retrieve_existing(customer_id)
      ::Stripe::Customer.retrieve(customer_id)
    end

    def free_price
      plan = ::Plan.find_by_slug!("free")
      plan.price_for("month") || raise(ActiveRecord::RecordNotFound, "Free plan price not found")
    end
  end
end
