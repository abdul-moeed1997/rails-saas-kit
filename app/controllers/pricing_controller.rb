class PricingController < ApplicationController
  layout "marketing"

  def index
    @plans = Plan.visible.ordered.includes(:prices, plan_features: :feature)
    @features = Feature.order(:name)
  end
end
