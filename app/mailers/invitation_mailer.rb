class InvitationMailer < ApplicationMailer
  include MailerSubdomainUrls

  def invite(invitation)
    @invitation = invitation
    @account = invitation.account
    @inviter = invitation.invited_by
    @accept_url = accept_invitation_url(invitation.token, **workspace_url_options(@account))

    mail(
      to: invitation.email,
      subject: t(".subject", account_name: @account.name, app_name: t("app_name"))
    )
  end
end
