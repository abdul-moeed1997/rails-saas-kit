class InvitationsController < ApplicationController
  before_action :authenticate_user!
  around_action :with_current_account_tenant

  def new
    @invitation = Invitation.new
  end

  def create
    @invitation = current_user.account.invitations.build(invitation_params)
    @invitation.invited_by = current_user

    if @invitation.save
      InvitationMailer.invite(@invitation).deliver_now
      redirect_to dashboard_path, notice: "Invitation sent to #{@invitation.email}."
    else
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    invitation = current_user.account.invitations.pending.find(params[:id])
    invitation.destroy!
    redirect_to dashboard_path, notice: "Invitation cancelled."
  end

  private

  def with_current_account_tenant
    ActsAsTenant.with_tenant(current_user.account) { yield }
  end

  def invitation_params
    params.require(:invitation).permit(:email)
  end
end
