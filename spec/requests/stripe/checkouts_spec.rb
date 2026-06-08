require "rails_helper"

RSpec.describe "Stripe checkouts", type: :request do
  before { load_billing_catalog! }

  let(:account) { create(:account, subdomain: "acme") }
  let(:user) { create(:user, account: account) }

  before do
    ActsAsTenant.with_tenant(account) do
      create(:subscription, account: account, price: free_price, status: "active")
    end
    sign_in user
  end

  describe "POST /stripe/checkout" do
    it "redirects to stripe checkout for a paid plan" do
      pro_monthly_price.update!(stripe_price_id: "price_pro_month")

      allow(Stripe::Customer).to receive(:create).and_return(
        Stripe::Customer.construct_from(id: "cus_new")
      )
      allow(Stripe::Checkout::Session).to receive(:create).and_return(
        Stripe::Checkout::Session.construct_from(url: "https://checkout.stripe.com/test")
      )

      post stripe_checkout_path, params: { plan_slug: "pro", interval: "month" }

      expect(response).to redirect_to("https://checkout.stripe.com/test")
    end

    it "rejects checkout for the free plan" do
      post stripe_checkout_path, params: { plan_slug: "free", interval: "month" }

      expect(response).to redirect_to(dashboard_path)
      visit_workspace_dashboard!(account)
      expect(response.body).to include("Free plan")
    end

    it "requires authentication" do
      sign_out user
      post stripe_checkout_path, params: { plan_slug: "pro", interval: "month" }
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
