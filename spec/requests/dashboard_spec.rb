require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  before { load_billing_catalog! }

  describe "GET /dashboard" do
    it "redirects to sign in when not authenticated" do
      get dashboard_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "shows the current user's email when authenticated on the workspace subdomain" do
      user = create(:user)
      sign_in user
      host! "#{user.account.subdomain}.example.com"

      get dashboard_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(user.email)
    end

    it "redirects to the workspace subdomain from the bare domain" do
      user = create(:user)
      sign_in user

      get dashboard_path

      expect(response).to redirect_to(workspace_url_for(user.account))
    end

    it "shows an active invite button for owners on a Pro plan" do
      account = create(:account, subdomain: "acme")
      create_pro_subscription(account)
      owner = create(:user, account: account)
      sign_in owner
      host! "acme.example.com"

      get dashboard_path

      expect(response.body).to include('href="' + new_invitation_path + '"')
      expect(response.body).to include("bg-indigo-600")
      expect(response.body).not_to include("cursor-not-allowed")
    end

    it "shows a disabled invite button for members on a Pro plan" do
      account = create(:account, subdomain: "acme")
      create_pro_subscription(account)
      create(:user, account: account, email: "founder@acme.com")
      member = create(:user, :member, account: account, email: "member@acme.com")
      sign_in member
      host! "acme.example.com"

      get dashboard_path

      expect(response.body).not_to include('href="' + new_invitation_path + '"')
      expect(response.body).to include("Invite teammate", "bg-zinc-200", "cursor-not-allowed", 'aria-disabled="true"')
    end

    it "shows a disabled invite button on the Free plan" do
      account = create(:account, subdomain: "acme")
      ActsAsTenant.with_tenant(account) do
        create(:subscription, account: account, price: free_price, status: "active")
      end
      owner = create(:user, account: account)
      sign_in owner
      host! "acme.example.com"

      get dashboard_path

      expect(response.body).not_to include('href="' + new_invitation_path + '"')
      expect(response.body).to include("Invite teammate", "bg-zinc-200", "cursor-not-allowed")
    end
  end
end
