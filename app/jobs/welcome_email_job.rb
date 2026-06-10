class WelcomeEmailJob < ApplicationJob
  queue_as :mailers

  def perform(user_id)
    user = User.find(user_id)

    I18n.with_locale(MailerLocale.locale_for(user)) do
      UserMailer.welcome(user).deliver_now
    end
  end
end
