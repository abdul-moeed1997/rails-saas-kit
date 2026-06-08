module Stripe
  class WebhookProcessor
    HANDLERS = {
      "checkout.session.completed" => :handle_checkout_completed,
      "customer.subscription.created" => :handle_subscription_event,
      "customer.subscription.updated" => :handle_subscription_event,
      "customer.subscription.deleted" => :handle_subscription_deleted,
      "invoice.payment_failed" => :handle_invoice_payment_failed,
      "invoice.paid" => :handle_invoice_paid
    }.freeze

    def self.call(event)
      new(event).call
    end

    def initialize(event)
      @event = event
    end

    def call
      handler = HANDLERS[@event.type]
      return unless handler

      send(handler)
    end

    private

    def handle_checkout_completed
      session = @event.data.object
      return unless session.mode == "subscription"

      account = account_from_reference(session.client_reference_id, session.metadata)
      return unless account

      if session.customer.present?
        link_customer(account, session.customer)
      end

      return unless session.subscription.present?

      subscription_id = session.subscription
      subscription_id = subscription_id.id if subscription_id.respond_to?(:id)

      stripe_subscription = ::Stripe::Subscription.retrieve(
        subscription_id,
        expand: [ "items.data.price", "items.data" ]
      )
      SubscriptionSyncer.call(stripe_subscription:, account:)
    end

    def handle_subscription_event
      stripe_subscription = @event.data.object
      SubscriptionSyncer.call(stripe_subscription:)
    end

    def handle_subscription_deleted
      stripe_subscription = @event.data.object
      subscription = ActsAsTenant.without_tenant do
        ::Subscription.find_by(stripe_subscription_id: stripe_subscription.id)
      end
      return unless subscription

      ActsAsTenant.with_tenant(subscription.account) do
        Subscriptions::ProvisionFree.reset_to_free!(subscription)
      end
    end

    def handle_invoice_payment_failed
      update_subscription_status(@event.data.object.subscription, "past_due")
    end

    def handle_invoice_paid
      stripe_subscription_id = @event.data.object.subscription
      return unless stripe_subscription_id

      subscription = ActsAsTenant.without_tenant do
        ::Subscription.find_by(stripe_subscription_id: stripe_subscription_id)
      end
      return unless subscription&.status == "past_due"

      ActsAsTenant.with_tenant(subscription.account) do
        subscription.update!(status: "active")
      end
    end

    def link_customer(account, customer_id)
      ActsAsTenant.with_tenant(account) do
        subscription = account.subscription || Subscriptions::ProvisionFree.call(account)
        subscription.update!(stripe_customer_id: customer_id)
      end
    end

    def account_from_reference(client_reference_id, metadata)
      account_id = client_reference_id.presence || metadata&.account_id || metadata&.[]("account_id")
      ::Account.find_by(id: account_id) if account_id.present?
    end

    def update_subscription_status(stripe_subscription_id, status)
      return unless stripe_subscription_id

      subscription = ActsAsTenant.without_tenant do
        ::Subscription.find_by(stripe_subscription_id: stripe_subscription_id)
      end
      return unless subscription

      ActsAsTenant.with_tenant(subscription.account) do
        subscription.update!(status: status)
      end
    end
  end
end
