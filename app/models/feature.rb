# Global catalog — shared across all accounts (not tenant-scoped).
class Feature < ApplicationRecord
  has_many :plan_features, dependent: :destroy
  has_many :plans, through: :plan_features

  validates :key, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_]+\z/ }
  validates :name, presence: true
end
