class DashboardController < ApplicationController
  before_action :authenticate_user!
  around_action :with_current_account_tenant

  def show
    @team_members = current_user.account.users.order(:email)
    @pending_invitations = current_user.account.invitations.pending.ordered
  end

  private

  def with_current_account_tenant
    ActsAsTenant.with_tenant(current_user.account) { yield }
  end
end
