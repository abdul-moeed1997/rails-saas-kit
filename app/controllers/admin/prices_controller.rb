# frozen_string_literal: true

module Admin
  class PricesController < BaseController
    before_action :set_plan
    before_action :set_price, only: %i[edit update]

    def new
      @price = @plan.prices.build(currency: "usd", active: true)
      authorize_admin(@price)
    end

    def create
      @price = @plan.prices.build(price_params)
      authorize_admin(@price)

      if @price.save
        apply_stripe_sync_result(Stripe::CatalogSyncer.sync_price!(@price))
        redirect_to admin_plan_path(@plan), notice: t("admin.prices.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize_admin(@price)
    end

    def update
      authorize_admin(@price)
      previous_amount_cents = @price.amount_cents

      if amount_changing?(previous_amount_cents) && @price.stripe_price_id.present?
        deactivate_and_replace_price(previous_amount_cents)
      elsif @price.update(price_params)
        apply_stripe_sync_result(Stripe::CatalogSyncer.sync_price!(@price, previous_amount_cents:))
        redirect_to admin_plan_path(@plan), notice: t("admin.prices.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_plan
      @plan = Plan.find(params[:plan_id])
    end

    def set_price
      @price = @plan.prices.find(params[:id])
    end

    def price_params
      params.require(:price).permit(:amount_cents, :interval, :active, :currency)
    end

    def amount_changing?(previous_amount_cents)
      price_params[:amount_cents].present? && price_params[:amount_cents].to_i != previous_amount_cents
    end

    def deactivate_and_replace_price(previous_amount_cents)
      @price.update!(active: false)
      @price = @plan.prices.create!(
        price_params.merge(interval: @price.interval, currency: @price.currency)
      )
      apply_stripe_sync_result(Stripe::CatalogSyncer.sync_price!(@price, previous_amount_cents:))
      redirect_to admin_plan_path(@plan), notice: t("admin.prices.updated")
    rescue ActiveRecord::RecordInvalid
      @price = @plan.prices.build(price_params)
      render :edit, status: :unprocessable_entity
    end
  end
end
