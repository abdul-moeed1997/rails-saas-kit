class InvitationsController < ApplicationController
  include AccountEntitlements

  before_action :authenticate_user!
  before_action -> { require_feature!(:invitations) }, only: %i[new create]
  before_action :require_seat_available!, only: %i[new create]
  around_action :with_current_account_tenant

  def new
    @invitation = current_user.account.invitations.build
    authorize @invitation
  end

  def create
    @invitation = current_user.account.invitations.build(invitation_params)
    @invitation.invited_by = current_user
    authorize @invitation

    if @invitation.save
      InvitationMailer.invite(@invitation).deliver_now
      redirect_to dashboard_path, notice: t(".notice", email: @invitation.email)
    else
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    invitation = current_user.account.invitations.pending.find(params[:id])
    authorize invitation
    invitation.destroy!
    redirect_to dashboard_path, notice: t(".notice")
  end

  private

  def with_current_account_tenant
    ActsAsTenant.with_tenant(current_user.account) { yield }
  end

  def invitation_params
    params.require(:invitation).permit(:email)
  end
end
