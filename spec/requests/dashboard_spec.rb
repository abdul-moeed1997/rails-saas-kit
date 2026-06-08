require "rails_helper"

RSpec.describe "Dashboard", type: :request do
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
  end
end
