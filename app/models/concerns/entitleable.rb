module Entitleable
  extend ActiveSupport::Concern

  def feature_enabled?(key)
    plan_feature_for(key)&.enabled? || false
  end

  def feature_limit(key)
    plan_feature_for(key)&.limit_value
  end

  private

  def plan_feature_for(key)
    plan_features.joins(:feature).find_by(features: { key: key.to_s })
  end
end
