class DashboardController < ApplicationController
  before_action :authenticate_user!
  around_action :with_current_account_tenant

  def show
    @team_members = current_user.account.users.order(:email)
    @pending_invitations = current_user.account.invitations.pending.ordered
    @subscription = current_user.account.subscription
    @seat_limit = current_user.account.feature_limit(:seats)
    @seats_used = @team_members.size + @pending_invitations.size
  end

  private

  def with_current_account_tenant
    ActsAsTenant.with_tenant(current_user.account) { yield }
  end
end
