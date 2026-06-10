module MailerLocale
  extend ActiveSupport::Concern

  module_function

  def locale_for(recipient)
    return I18n.default_locale unless recipient.respond_to?(:locale)

    locale = recipient.locale&.to_sym
    return I18n.default_locale if locale.blank?
    return locale if I18n.available_locales.include?(locale)

    I18n.default_locale
  end
end
