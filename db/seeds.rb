# frozen_string_literal: true

features = [
  { key: "seats", name: "Team seats", description: "Maximum users per account" },
  { key: "invitations", name: "Team invitations", description: "Invite teammates to your account" },
  { key: "sso", name: "Single sign-on", description: "SAML/OIDC SSO for your organization" },
  { key: "audit_log", name: "Audit log", description: "Activity and security audit trail" },
  { key: "priority_support", name: "Priority support", description: "Faster support response times" }
].index_by { |attrs| attrs[:key] }

features.each_value do |attrs|
  Feature.find_or_create_by!(key: attrs[:key]) do |feature|
    feature.name = attrs[:name]
    feature.description = attrs[:description]
  end
end

plans_config = [
  {
    name: "Free",
    slug: "free",
    description: "For individuals getting started",
    position: 0,
    prices: { month: 0, year: 0 },
    entitlements: {
      "seats" => { enabled: true, limit_value: 1 },
      "invitations" => { enabled: false },
      "sso" => { enabled: false },
      "audit_log" => { enabled: false },
      "priority_support" => { enabled: false }
    }
  },
  {
    name: "Pro",
    slug: "pro",
    description: "For growing teams",
    position: 1,
    highlighted: true,
    prices: { month: 2900, year: 29_000 },
    entitlements: {
      "seats" => { enabled: true, limit_value: 10 },
      "invitations" => { enabled: true },
      "sso" => { enabled: false },
      "audit_log" => { enabled: false },
      "priority_support" => { enabled: false }
    }
  },
  {
    name: "Business",
    slug: "business",
    description: "For organizations that need more",
    position: 2,
    prices: { month: 9900, year: 99_000 },
    entitlements: {
      "seats" => { enabled: true, limit_value: 50 },
      "invitations" => { enabled: true },
      "sso" => { enabled: true },
      "audit_log" => { enabled: true },
      "priority_support" => { enabled: true }
    }
  }
]

plans_config.each do |config|
  plan = Plan.find_or_create_by!(slug: config[:slug]) do |record|
    record.name = config[:name]
    record.description = config[:description]
    record.position = config[:position]
    record.highlighted = config[:highlighted] || false
    record.status = "active"
  end

  plan.update!(
    name: config[:name],
    description: config[:description],
    position: config[:position],
    highlighted: config[:highlighted] || false
  )

  config[:prices].each do |interval, amount_cents|
    price = Price.find_or_initialize_by(plan: plan, interval: interval.to_s)
    price.assign_attributes(amount_cents: amount_cents, currency: "usd", active: true)
    price.save!
  end

  config[:entitlements].each do |feature_key, attrs|
    feature = Feature.find_by!(key: feature_key)
    plan_feature = PlanFeature.find_or_initialize_by(plan: plan, feature: feature)
    plan_feature.enabled = attrs[:enabled]
    plan_feature.limit_value = attrs[:limit_value]
    plan_feature.save!
  end
end
