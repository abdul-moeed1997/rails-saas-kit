module Stripe
  class BillingPortalsController < ApplicationController
    before_action :authenticate_user!
    around_action :with_current_account_tenant

    def create
      authorize current_user.account.subscription || Subscription.new(account: current_user.account), :manage?

      portal_url = BillingPortalSessionCreator.call(
        account: current_user.account,
        return_url: dashboard_url
      )

      redirect_to portal_url, allow_other_host: true
    rescue BillingPortalSessionCreator::Error => e
      redirect_to dashboard_path, alert: e.message
    end

    private

    def with_current_account_tenant
      ActsAsTenant.with_tenant(current_user.account) { yield }
    end
  end
end
