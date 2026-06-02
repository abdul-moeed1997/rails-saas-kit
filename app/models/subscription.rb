class Subscription < ApplicationRecord
  acts_as_tenant :account

  STATUSES = %w[trialing active past_due canceled paused incomplete].freeze

  belongs_to :price
  has_one :plan, through: :price

  validates :status, presence: true, inclusion: { in: STATUSES }

  delegate :feature_enabled?, :feature_limit, to: :plan

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
end
