module Roleable
  extend ActiveSupport::Concern

  ROLES = %w[owner admin member].freeze

  included do
    enum :role, ROLES.index_by(&:itself), default: :member, validate: true
  end

  def admin_or_owner?
    owner? || admin?
  end
end
