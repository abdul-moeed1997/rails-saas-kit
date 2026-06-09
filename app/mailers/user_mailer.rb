class UserMailer < ApplicationMailer
  include MailerSubdomainUrls

  def welcome(user)
    @user = user
    @account = user.account
    @dashboard_url = dashboard_url(**workspace_url_options(@account))

    mail(
      to: user.email,
      subject: "Welcome to #{@account.name} on Rails Saas Kit"
    )
  end
end
