class InvitationMailer < ApplicationMailer
  include MailerSubdomainUrls

  def invite(invitation)
    @invitation = invitation
    @account = invitation.account
    @inviter = invitation.invited_by
    @accept_url = accept_invitation_url(invitation.token, **workspace_url_options(@account))

    mail(
      to: invitation.email,
      subject: "Join #{@account.name} on Rails Saas Kit"
    )
  end
end
