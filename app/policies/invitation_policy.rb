# frozen_string_literal: true

class InvitationPolicy < ApplicationPolicy
  def create?
    team_manager? && same_account?
  end

  def destroy?
    create?
  end
end
