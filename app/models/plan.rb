# Global catalog — shared across all accounts (not tenant-scoped).
class Plan < ApplicationRecord
  include Entitleable

  STATUSES = %w[active archived draft].freeze

  has_many :prices, dependent: :destroy
  has_many :plan_features, dependent: :destroy
  has_many :features, through: :plan_features

  accepts_nested_attributes_for :plan_features, allow_destroy: false

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :visible, -> { where(status: "active") }
  scope :ordered, -> { order(:position, :name) }

  def price_for(interval)
    prices.active.find_by(interval: interval)
  end

  def self.find_by_slug!(slug)
    find_by!(slug: slug)
  end
end
