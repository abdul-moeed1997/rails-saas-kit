# Global catalog — shared across all accounts (not tenant-scoped).
class Price < ApplicationRecord
  INTERVALS = %w[month year].freeze

  belongs_to :plan
  has_many :subscriptions, dependent: :restrict_with_error

  validates :amount_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :currency, presence: true
  validates :interval, presence: true, inclusion: { in: INTERVALS }
  validates :interval, uniqueness: { scope: :plan_id }

  scope :active, -> { where(active: true) }

  def amount_dollars
    amount_cents / 100.0
  end
end
