class LocalesController < ApplicationController
  def update
    locale = params.require(:locale).to_sym

    unless I18n.available_locales.include?(locale)
      redirect_back fallback_location: root_path, alert: t("locales.invalid", default: "Language not available.")
      return
    end

    if user_signed_in?
      current_user.update!(locale: locale.to_s)
    else
      session[:locale] = locale.to_s
    end

    redirect_back fallback_location: root_path, notice: t("locales.update.notice")
  end
end
