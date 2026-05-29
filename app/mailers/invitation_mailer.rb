class InvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @account = invitation.account
    @inviter = invitation.invited_by
    @accept_url = accept_invitation_url(invitation.token, **invitation_url_options(@account))

    mail(
      to: invitation.email,
      subject: "Join #{@account.name} on Rails Saas Kit"
    )
  end

  private

  def invitation_url_options(account)
    options = Rails.application.config.action_mailer.default_url_options.dup
    options[:host] = "#{account.subdomain}.#{base_host}"
    options
  end

  def base_host
    host = Rails.application.config.action_mailer.default_url_options[:host]
    return "lvh.me" if host.in?(%w[localhost 127.0.0.1])

    host.delete_prefix("www.")
  end
end
