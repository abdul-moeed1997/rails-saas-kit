class Subscription < ApplicationRecord
  acts_as_tenant :account

  STATUSES = %w[trialing active past_due canceled paused incomplete].freeze

  belongs_to :price
  has_one :plan, through: :price

  validates :status, presence: true, inclusion: { in: STATUSES }

  delegate :feature_enabled?, :feature_limit, to: :plan

  scope :active_subscriptions, -> { where(status: %w[trialing active]) }
  scope :past_due_subscriptions, -> { where(status: "past_due") }

  def self.find_by_stripe_subscription_id!(stripe_subscription_id)
    ActsAsTenant.without_tenant do
      find_by!(stripe_subscription_id: stripe_subscription_id)
    end
  end

  def active?
    status.in?(%w[trialing active])
  end

  def canceled?
    status == "canceled"
  end

  def stripe_managed?
    stripe_subscription_id.present?
  end

  def sync_from_stripe!(stripe_subscription)
    price = Price.find_by!(stripe_price_id: stripe_price_id_from(stripe_subscription))

    period_start, period_end = billing_period_from(stripe_subscription)

    update!(
      price: price,
      status: map_stripe_status(stripe_subscription.status),
      stripe_subscription_id: stripe_subscription.id,
      stripe_customer_id: stripe_customer_id_from(stripe_subscription),
      current_period_start: time_from_stripe(period_start),
      current_period_end: time_from_stripe(period_end),
      trial_ends_at: time_from_stripe(stripe_subscription.trial_end),
      cancel_at_period_end: stripe_subscription.cancel_at_period_end,
      canceled_at: time_from_stripe(stripe_subscription.canceled_at)
    )
  end

  private

  def billing_period_from(stripe_subscription)
    if stripe_subscription.respond_to?(:current_period_start) && stripe_subscription.current_period_start.present?
      return [ stripe_subscription.current_period_start, stripe_subscription.current_period_end ]
    end

    item = stripe_subscription.items&.data&.first
    return [ nil, nil ] unless item

    [
      stripe_attribute(item, :current_period_start),
      stripe_attribute(item, :current_period_end)
    ]
  end

  def stripe_attribute(object, key)
    return object.public_send(key) if object.respond_to?(key)

    object[key] if object.respond_to?(:[])
  end

  def stripe_customer_id_from(stripe_subscription)
    customer = stripe_subscription.customer
    customer.is_a?(String) ? customer : customer&.id
  end

  def stripe_price_id_from(stripe_subscription)
    price = stripe_subscription.items.data.first.price
    price.is_a?(String) ? price : price.id
  end

  def map_stripe_status(stripe_status)
    case stripe_status
    when "trialing" then "trialing"
    when "active" then "active"
    when "past_due" then "past_due"
    when "canceled" then "canceled"
    when "paused" then "paused"
    when "incomplete", "incomplete_expired", "unpaid" then "incomplete"
    else stripe_status
    end
  end

  def time_from_stripe(timestamp)
    return if timestamp.blank?

    Time.zone.at(timestamp)
  end
end
