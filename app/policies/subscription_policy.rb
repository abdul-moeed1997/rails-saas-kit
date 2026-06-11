# frozen_string_literal: true

class SubscriptionPolicy < ApplicationPolicy
  def manage?
    billing_manager?
  end
end
