class UserMailer < ApplicationMailer
  include MailerSubdomainUrls

  def welcome(user)
    @user = user
    @account = user.account
    @dashboard_url = dashboard_url(**workspace_url_options(@account))

    mail(
      to: user.email,
      subject: t(".subject", account_name: @account.name, app_name: t("app_name"))
    )
  end
end
