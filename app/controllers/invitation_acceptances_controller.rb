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
    return handle_seat_limit_reached unless seat_available?

    @user = User.new(
      email: @invitation.email,
      password: user_params[:password],
      password_confirmation: user_params[:password_confirmation],
      account: @invitation.account,
      locale: I18n.locale.to_s
    )

    saved = ActsAsTenant.with_tenant(@invitation.account) { @user.save }

    if saved
      mark_invitation_accepted!
      sign_in(@user)
      redirect_to workspace_dashboard_url(@invitation.account),
        allow_other_host: true,
        notice: t(".notice", account_name: @invitation.account.name)
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
    redirect_to root_path, alert: t("invitation_acceptances.missing_invitation")
  end

  def handle_unavailable_invitation
    key = if @invitation.accepted_at?
      :already_accepted
    elsif @invitation.expired?
      :expired
    else
      :invalid
    end

    redirect_to root_path, alert: t("invitation_acceptances.#{key}")
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def seat_available?
    account = @invitation.account
    limit = account.feature_limit(:seats)
    return true if limit.nil?

    # The invite already reserved a seat; accepting converts pending → member.
    used = account.users.count + account.invitations.pending.where.not(id: @invitation.id).count
    used < limit
  end

  def handle_seat_limit_reached
    redirect_to root_path, alert: t("invitation_acceptances.seat_limit_reached")
  end
end
