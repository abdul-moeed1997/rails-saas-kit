Rails.application.config.stripe = Rails.application.config_for(:stripe)

Stripe.api_key = Rails.application.credentials.dig(:stripe, :secret_key)
