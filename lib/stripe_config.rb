module StripeConfig
  module_function

  def trial_period_days
    Rails.application.config.stripe.fetch(:trial_period_days)
  end
end
