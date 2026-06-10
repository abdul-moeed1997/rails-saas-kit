module PricingHelper
  def format_price_cents(cents, currency: "usd", precision: nil)
    return t("helpers.pricing.free") if cents.zero?

    prec = precision || ((cents % 100).zero? ? 0 : 2)
    number_to_currency(cents / 100.0, unit: currency_symbol(currency), precision: prec)
  end

  def pricing_amount_display(price)
    return { amount: t("helpers.pricing.free"), period: nil, subtext: nil } if price.nil? || price.amount_cents.zero?

    {
      amount: format_price_cents(price.amount_cents),
      period: t("helpers.pricing.per_month"),
      subtext: nil
    }
  end

  def pricing_amount_display_annual(month_price, year_price)
    return pricing_amount_display(month_price) if year_price.nil? || year_price.amount_cents.zero?

    monthly_equiv_cents = (year_price.amount_cents / 12.0).round
    {
      amount: format_price_cents(monthly_equiv_cents, precision: (monthly_equiv_cents % 100).zero? ? 0 : 2),
      period: t("helpers.pricing.per_month"),
      subtext: t("helpers.pricing.billed_yearly", amount: format_price_cents(year_price.amount_cents))
    }
  end

  def pricing_feature_label(plan, feature)
    plan_feature = plan.plan_features.find { |pf| pf.feature_id == feature.id }
    return tag.span("—", class: "text-zinc-300") unless plan_feature&.enabled?

    if plan_feature.limit_value.present?
      tag.span(feature_limit_label(feature, plan_feature.limit_value), class: "text-sm font-medium text-zinc-700")
    else
      pricing_check_icon
    end
  end

  def pricing_card_features(plan, features)
    features.filter_map do |feature|
      summary = pricing_card_feature_summary(plan, feature)
      next unless summary

      summary
    end
  end

  def pricing_card_feature_summary(plan, feature)
    plan_feature = plan.plan_features.find { |pf| pf.feature_id == feature.id }
    return unless plan_feature&.enabled?

    if plan_feature.limit_value.present?
      feature_limit_label(feature, plan_feature.limit_value)
    else
      feature.name
    end
  end

  def annual_savings_percent(plan)
    month_cents = plan.prices.find { |p| p.interval == "month" }&.amount_cents
    year_cents = plan.prices.find { |p| p.interval == "year" }&.amount_cents
    return nil if month_cents.nil? || year_cents.nil? || month_cents.zero?

    annual_monthly = month_cents * 12
    return nil if annual_monthly <= year_cents

    ((annual_monthly - year_cents) * 100.0 / annual_monthly).round
  end

  def pricing_cta_label(plan)
    if plan.slug == "free"
      user_signed_in? ? t("helpers.pricing.go_to_dashboard") : t("helpers.pricing.get_started_free")
    elsif user_signed_in?
      t("helpers.pricing.upgrade_to", plan: plan.name)
    else
      t("helpers.pricing.start_free_trial")
    end
  end

  def pricing_cta_link_path(plan, interval: "month")
    if plan.slug == "free"
      user_signed_in? ? dashboard_path : new_user_registration_path
    else
      new_user_registration_path(plan: plan.slug, interval: interval)
    end
  end

  def pricing_cta_checkout?(plan)
    plan.slug != "free" && user_signed_in?
  end

  def pricing_savings_template
    t("helpers.pricing.savings_vs_monthly", percent: "%{percent}")
  end

  private

  def currency_symbol(currency)
    currency.to_s.downcase == "usd" ? "$" : "#{currency.upcase} "
  end

  def feature_limit_label(feature, limit)
    case feature.key
    when "seats"
      t("helpers.pricing.seats", count: limit)
    else
      feature.name
    end
  end

  def pricing_check_icon
    tag.svg(
      viewBox: "0 0 20 20",
      fill: "currentColor",
      class: "inline-block size-5 text-indigo-600",
      aria: { hidden: true }
    ) do
      tag.path(
        fill_rule: "evenodd",
        d: "M16.704 4.153a.75.75 0 0 1 .143 1.052l-8 10.5a.75.75 0 0 1-1.127.075l-4.5-4.5a.75.75 0 0 1 1.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 0 1 1.05-.143Z",
        clip_rule: "evenodd"
      )
    end
  end
end
