module BillingCatalogHelpers
  def load_billing_catalog!
    load Rails.root.join("db/seeds.rb")
  end

  def free_price
    Plan.find_by_slug!("free").price_for("month")
  end

  def pro_monthly_price
    Plan.find_by_slug!("pro").price_for("month")
  end

  def create_pro_subscription(account, traits = {})
    price = pro_monthly_price
    ActsAsTenant.with_tenant(account) do
      create(:subscription, { account: account, price: price, status: "active" }.merge(traits))
    end
  end
end

RSpec.configure do |config|
  config.include BillingCatalogHelpers
end
