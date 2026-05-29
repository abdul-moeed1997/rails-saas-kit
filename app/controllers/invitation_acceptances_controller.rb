class InvitationAcceptancesController < ApplicationController
  before_action :set_invitation

  def new
    return handle_missing_invitation unless @invitation
    return handle_unavailable_invitation unless @invitation.pending?

    @user = User.new(email: @invitation.email)
  end

  def create
    return handle_missing_invitation unless @invitation
    return handle_unavailable_invitation unless @invitation.pending?

    @user = User.new(
      email: @invitation.email,
      password: user_params[:password],
      password_confirmation: user_params[:password_confirmation],
      account: @invitation.account
    )

    saved = ActsAsTenant.with_tenant(@invitation.account) { @user.save }

    if saved
      mark_invitation_accepted!
      sign_in(@user)
      redirect_to dashboard_path, notice: "Welcome to #{@invitation.account.name}!"
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def set_invitation
    @invitation = ActsAsTenant.without_tenant { Invitation.find_by(token: params[:token]) }
  end

  def mark_invitation_accepted!
    ActsAsTenant.without_tenant do
      @invitation.update!(accepted_at: Time.current)
    end
  end

  def handle_missing_invitation
    redirect_to root_path,
      alert: "This invitation was cancelled or is no longer valid. Ask your teammate to send a new invitation."
  end

  def handle_unavailable_invitation
    message = if @invitation.accepted_at?
      "This invitation has already been accepted."
    elsif @invitation.expired?
      "This invitation has expired. Ask your teammate to send a new one."
    else
      "This invitation is no longer valid."
    end

    redirect_to root_path, alert: message
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
