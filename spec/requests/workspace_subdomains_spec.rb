require "rails_helper"

RSpec.describe "Workspace subdomains", type: :request do
  let(:password) { "password123456" }

  describe "GET / with an unknown subdomain" do
    it "returns not found" do
      host! "other.lvh.me"

      get root_path

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Workspace not found")
    end
  end

  describe "GET / with a valid subdomain" do
    before { create(:account, subdomain: "acme") }

    it "allows the request" do
      host! "acme.lvh.me"

      get root_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET / without a subdomain" do
    it "allows the request" do
      host! "lvh.me"

      get root_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /dashboard with an unknown subdomain" do
    let(:account) { create(:account, subdomain: "acme") }
    let(:user) { create(:user, account: account) }

    before { sign_in user }

    it "returns not found instead of showing the signed-in dashboard" do
      host! "other.lvh.me"

      get dashboard_path

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Workspace not found")
    end
  end

  describe "GET /dashboard on another workspace subdomain" do
    let(:account) { create(:account, subdomain: "acme") }
    let(:other_account) { create(:account, subdomain: "beta") }
    let(:user) { create(:user, account: account) }

    before do
      other_account
      sign_in user
    end

    it "redirects to the user's workspace" do
      host! "beta.lvh.me"

      get dashboard_path

      expect(response).to redirect_to(workspace_url_for(account))
    end
  end

  describe "GET /users/sign_in when already authenticated" do
    let(:account) { create(:account, subdomain: "beta") }
    let(:user) { create(:user, account: account) }

    before { sign_in user }

    it "redirects to the workspace subdomain" do
      host! "lvh.me"

      get new_user_session_path

      expect(response).to redirect_to(workspace_url_for(account))
    end
  end

  describe "GET /users/sign_in on a workspace subdomain" do
    it "redirects to the apex sign-in page" do
      host! "beta.example.com"

      get new_user_session_path

      expect(response).to redirect_to("http://example.com/users/sign_in")
    end
  end

  describe "GET /dashboard without authentication on a workspace subdomain" do
    before { create(:account, subdomain: "beta") }

    it "redirects to the apex sign-in page" do
      host! "beta.example.com"

      get dashboard_path

      expect(response).to redirect_to("http://example.com/users/sign_in")
    end
  end

  describe "sign in on the workspace subdomain" do
    let(:account) { create(:account, subdomain: "beta") }
    let(:user) { create(:user, account: account, password: password, password_confirmation: password) }

    it "signs in and reaches the dashboard on the same subdomain" do
      host! "beta.example.com"

      post user_session_path,
           params: { user: { email: user.email, password: password } }

      expect(response).to redirect_to(dashboard_path)
      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Dashboard", user.email)
    end
  end

  describe "sign in from the bare domain" do
    let(:account) { create(:account, subdomain: "beta") }
    let(:user) { create(:user, account: account, password: password, password_confirmation: password) }

    it "redirects to the user's workspace subdomain" do
      host! "lvh.me"

      post user_session_path,
           params: { user: { email: user.email, password: password } }

      expect(response).to redirect_to(workspace_url_for(account))
    end
  end
end
