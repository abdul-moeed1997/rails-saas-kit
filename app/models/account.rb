class Account < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_one :subscription, dependent: :destroy

  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true

  def feature_enabled?(key)
    subscription&.feature_enabled?(key) || false
  end

  def feature_limit(key)
    subscription&.feature_limit(key)
  end

  def current_plan
    subscription&.plan
  end
end
