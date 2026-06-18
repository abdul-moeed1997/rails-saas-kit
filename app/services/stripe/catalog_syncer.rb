# frozen_string_literal: true

module Stripe
  class CatalogSyncer
    class Error < StandardError; end

    Result = Struct.new(:success?, :error, keyword_init: true)

    def self.sync_plan!(plan)
      new(plan: plan).sync_plan!
    end

    def self.sync_price!(price, previous_amount_cents: nil)
      new(price: price, previous_amount_cents: previous_amount_cents).sync_price!
    end

    def initialize(plan: nil, price: nil, previous_amount_cents: nil)
      @plan = plan || price&.plan
      @price = price
      @previous_amount_cents = previous_amount_cents
    end

    def sync_plan!
      return success if skip_stripe_sync?

      ensure_product!
      archive_product_if_needed!
      success
    rescue ::Stripe::StripeError => e
      failure(e.message)
    end

    def sync_price!
      return success if @price.amount_cents.zero?
      return success if skip_stripe_sync?

      product_result = self.class.sync_plan!(@plan)
      return product_result unless product_result.success?

      if @price.stripe_price_id.present? && amount_changed?
        archive_stripe_price(@price.stripe_price_id)
        create_stripe_price!
      elsif @price.stripe_price_id.blank?
        create_stripe_price!
      end

      success
    rescue ::Stripe::StripeError => e
      failure(e.message)
    end

    private

    def skip_stripe_sync?
      return true if @plan.slug == "free"

      prices = @plan.prices.active.to_a
      return false if prices.empty?

      prices.all? { |p| p.amount_cents.zero? }
    end

    def amount_changed?
      @previous_amount_cents.present? && @previous_amount_cents != @price.amount_cents
    end

    def ensure_product!
      if @plan.stripe_product_id.present?
        ::Stripe::Product.update(
          @plan.stripe_product_id,
          name: @plan.name,
          description: @plan.description,
          active: @plan.status == "active"
        )
      else
        product = ::Stripe::Product.create(
          name: @plan.name,
          description: @plan.description,
          metadata: { plan_id: @plan.id, plan_slug: @plan.slug }
        )
        @plan.update!(stripe_product_id: product.id)
      end
    end

    def archive_product_if_needed!
      return unless @plan.status == "archived" && @plan.stripe_product_id.present?

      ::Stripe::Product.update(@plan.stripe_product_id, active: false)
    end

    def create_stripe_price!
      stripe_price = ::Stripe::Price.create(
        product: @plan.stripe_product_id,
        unit_amount: @price.amount_cents,
        currency: @price.currency,
        recurring: { interval: @price.interval },
        metadata: { price_id: @price.id, plan_id: @plan.id }
      )
      @price.update!(stripe_price_id: stripe_price.id)
    end

    def archive_stripe_price(stripe_price_id)
      ::Stripe::Price.update(stripe_price_id, active: false)
    end

    def success
      Result.new(success?: true)
    end

    def failure(message)
      Result.new(success?: false, error: message)
    end
  end
end
