module Stripe
  class CheckoutsController < ApplicationController
    before_action :authenticate_user!
    around_action :with_current_account_tenant

    def new
      pending = session[:pending_checkout]&.with_indifferent_access
      @plan_slug = params[:plan_slug].presence || pending&.dig(:plan_slug)
      @interval = (params[:interval].presence || pending&.dig(:interval)).presence_in(::Price::INTERVALS) || "month"

      redirect_to pricing_path if @plan_slug.blank?
    end

    def create
      plan = ::Plan.find_by_slug!(checkout_plan_slug)
      interval = checkout_interval

      if plan.slug == "free"
        redirect_to dashboard_path, notice: t(".already_on_free")
        return
      end

      checkout_url = CheckoutSessionCreator.call(
        account: current_user.account,
        plan: plan,
        interval: interval,
        success_url: checkout_success_url,
        cancel_url: checkout_cancel_url
      )

      redirect_to checkout_url, allow_other_host: true
    rescue ActiveRecord::RecordNotFound
      redirect_to pricing_path, alert: t(".plan_not_found")
    rescue CheckoutSessionCreator::Error => e
      redirect_to pricing_path, alert: e.message
    end

    def success
      redirect_to dashboard_path, notice: t(".notice")
    end

    def cancel
      redirect_to pricing_path, alert: t(".alert")
    end

    private

    def checkout_plan_slug
      checkout_selection[:plan_slug].presence || raise(ActionController::ParameterMissing.new(:plan_slug))
    end

    def checkout_interval
      checkout_selection[:interval].presence || raise(ActionController::ParameterMissing.new(:interval))
    end

    def checkout_selection
      @checkout_selection ||= begin
        pending = session[:pending_checkout]&.with_indifferent_access
        selection = {
          plan_slug: params[:plan_slug].presence || pending&.dig(:plan_slug),
          interval: params[:interval].presence || pending&.dig(:interval) || "month"
        }
        session.delete(:pending_checkout) if selection[:plan_slug].present?
        selection
      end
    end

    def with_current_account_tenant
      ActsAsTenant.with_tenant(current_user.account) { yield }
    end
  end
end
