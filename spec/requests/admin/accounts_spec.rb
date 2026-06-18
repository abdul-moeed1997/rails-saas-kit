require "rails_helper"

RSpec.describe "Admin accounts", type: :request do
  let(:admin) { create(:user, :platform_admin) }

  before do
    load_billing_catalog!
    sign_in admin
  end

  describe "GET /admin/accounts" do
    it "lists accounts" do
      account = create(:account, name: "Acme Corp", subdomain: "acme")
      create(:user, account: account, email: "owner@acme.com")

      get admin_accounts_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Acme Corp", "acme")
    end
  end

  describe "GET /admin/accounts/:id" do
    it "shows account details" do
      account = create(:account, name: "Acme Corp", subdomain: "acme")
      owner = create(:user, account: account, email: "owner@acme.com")
      create_pro_subscription(account)

      get admin_account_path(account)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Acme Corp", owner.email, "Pro")
    end
  end

  describe "PATCH /admin/accounts/:id" do
    it "updates account attributes" do
      account = create(:account, name: "Acme Corp", subdomain: "acme")

      patch admin_account_path(account), params: { account: { name: "Acme Inc", subdomain: "acme" } }

      expect(response).to redirect_to(admin_account_path(account))
      expect(account.reload.name).to eq("Acme Inc")
    end
  end

  describe "POST /admin/accounts/:id/reset_subscription" do
    it "resets subscription to free" do
      account = create(:account, subdomain: "acme")
      create_pro_subscription(account)

      post reset_subscription_admin_account_path(account)

      expect(response).to redirect_to(admin_account_path(account))
      expect(account.reload.subscription.plan.slug).to eq("free")
    end
  end
end
