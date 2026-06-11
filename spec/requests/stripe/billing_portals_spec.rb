require "rails_helper"

RSpec.describe "Stripe billing portal", type: :request do
  before { load_billing_catalog! }

  let(:account) { create(:account, subdomain: "acme") }
  let(:user) { create(:user, account: account) }

  before do
    ActsAsTenant.with_tenant(account) do
      create(:subscription, :with_stripe_ids, account: account, price: pro_monthly_price, status: "trialing")
    end
    sign_in user
  end

  describe "POST /stripe/billing_portal" do
    it "redirects to the stripe customer portal" do
      allow(Stripe::BillingPortal::Session).to receive(:create).and_return(
        Stripe::BillingPortal::Session.construct_from(url: "https://billing.stripe.com/test")
      )

      post stripe_billing_portal_path

      expect(response).to redirect_to("https://billing.stripe.com/test")
    end

    it "does not let members open the billing portal" do
      member = create(:user, :member, account: account)
      sign_in member

      post stripe_billing_portal_path

      expect(response).to redirect_to(dashboard_path)
      visit_workspace_dashboard!(account)
      expect(response.body).to include("not allowed")
    end
  end
end
