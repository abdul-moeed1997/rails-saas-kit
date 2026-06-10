module LocaleHelper
  def locale_options
    I18n.available_locales.map do |locale|
      [ t("locales.#{locale}", default: locale.to_s.upcase), locale ]
    end
  end
end
