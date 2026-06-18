require "rails_helper"

RSpec.describe "Admin subscriptions", type: :request do
  let(:admin) { create(:user, :platform_admin) }

  before do
    load_billing_catalog!
    sign_in admin
  end

  describe "PATCH /admin/accounts/:account_id/subscription" do
    it "updates a local subscription" do
      account = create(:account, subdomain: "acme")
      ActsAsTenant.with_tenant(account) do
        create(:subscription, account: account, price: free_price, status: "active")
      end

      patch admin_account_subscription_path(account), params: {
        subscription: { price_id: pro_monthly_price.id, status: "active" }
      }

      expect(response).to redirect_to(admin_account_path(account))
      expect(account.reload.subscription.plan.slug).to eq("pro")
    end
  end
end
