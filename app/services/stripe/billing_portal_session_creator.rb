module Stripe
  class BillingPortalSessionCreator
    class Error < StandardError; end

    def self.call(account:, return_url:)
      new(account:, return_url:).call
    end

    def initialize(account:, return_url:)
      @account = account
      @return_url = return_url
    end

    def call
      customer_id = @account.subscription&.stripe_customer_id
      raise Error, I18n.t("services.stripe.billing_portal_session_creator.no_billing_account") if customer_id.blank?

      session = ::Stripe::BillingPortal::Session.create(
        customer: customer_id,
        return_url: @return_url
      )

      session.url
    end
  end
end
