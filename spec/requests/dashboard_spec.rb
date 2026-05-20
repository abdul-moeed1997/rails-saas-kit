require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  describe "GET /dashboard" do
    it "redirects to sign in when not authenticated" do
      get dashboard_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "shows the current user's email when authenticated" do
      user = create(:user)
      sign_in user

      get dashboard_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(user.email)
    end
  end
end
