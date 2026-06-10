module Locale
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale
  end

  private

  def switch_locale(&action)
    I18n.with_locale(resolve_locale, &action)
  end

  def resolve_locale
    locale_from_param ||
      locale_from_user ||
      locale_from_session ||
      locale_from_accept_language ||
      I18n.default_locale
  end

  def locale_from_param
    locale = params[:locale]&.to_sym
    locale if locale.present? && I18n.available_locales.include?(locale)
  end

  def locale_from_user
    return unless current_user.respond_to?(:locale)

    locale = current_user.locale&.to_sym
    locale if locale.present? && I18n.available_locales.include?(locale)
  end

  def locale_from_session
    locale = session[:locale]&.to_sym
    locale if locale.present? && I18n.available_locales.include?(locale)
  end

  def locale_from_accept_language
    return if request.env["HTTP_ACCEPT_LANGUAGE"].blank?

    request.env["HTTP_ACCEPT_LANGUAGE"]
      .scan(/^[a-z]{2}/)
      .flatten
      .map(&:to_sym)
      .find { |locale| I18n.available_locales.include?(locale) }
  end

  def persist_locale_for(user)
    return if user.locale.present?

    user.update(locale: I18n.locale.to_s)
  end
end
