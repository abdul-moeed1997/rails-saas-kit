# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    def show
      @accounts_count = Account.count
      @active_subscriptions_count = Subscription.active_subscriptions.count
      @plans_count = Plan.count
      @features_count = Feature.count
      @recent_accounts = Account.order(created_at: :desc).includes(subscription: { price: :plan }).limit(10)
    end
  end
end
