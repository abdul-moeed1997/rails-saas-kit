# Global catalog — shared across all accounts (not tenant-scoped).
class PlanFeature < ApplicationRecord
  belongs_to :plan
  belongs_to :feature

  validates :feature_id, uniqueness: { scope: :plan_id }
  validates :limit_value, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
end
