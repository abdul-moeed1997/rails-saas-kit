class StripeWebhookEvent < ApplicationRecord
  STATUSES = %w[processing processed failed].freeze

  validates :stripe_event_id, presence: true, uniqueness: true
  validates :event_type, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :processed, -> { where(status: "processed") }

  def failed?
    status == "failed"
  end
end
