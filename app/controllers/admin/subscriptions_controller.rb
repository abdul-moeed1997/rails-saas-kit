# frozen_string_literal: true

module Admin
  class SubscriptionsController < BaseController
    before_action :set_account
    before_action :set_subscription

    def edit
      authorize_admin(@subscription)
      @prices = Price.active.includes(:plan).joins(:plan).merge(Plan.ordered)
    end

    def update
      authorize_admin(@subscription)

      price = Price.find(subscription_params[:price_id])
      status = subscription_params[:status]

      Stripe::SubscriptionUpdater.call(subscription: @subscription, price:, status:)
      redirect_to admin_account_path(@account), notice: t("admin.subscriptions.updated")
    rescue Stripe::SubscriptionUpdater::Error, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      @prices = Price.active.includes(:plan).joins(:plan).merge(Plan.ordered)
      flash.now[:alert] = e.message
      render :edit, status: :unprocessable_entity
    end

    private

    def set_account
      @account = Account.find(params[:account_id])
    end

    def set_subscription
      @subscription = @account.subscription || Subscriptions::ProvisionFree.call(@account)
    end

    def subscription_params
      params.require(:subscription).permit(:price_id, :status)
    end
  end
end
