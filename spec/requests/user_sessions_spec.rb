require "rails_helper"

RSpec.describe "User sessions", type: :request do
  describe "POST /users/sign_in" do
    it "signs in and redirects to root" do
      user = create(:user, email: "session@example.com", password: "password123456", password_confirmation: "password123456")

      post user_session_path,
           params: {
             user: { email: user.email, password: "password123456" }
           }

      expect(response).to redirect_to(workspace_url_for(user.account))
      visit_workspace_dashboard!(user.account)
      expect(response.body).to include("session@example.com", "Dashboard")
    end

    it "re-renders sign in with errors when credentials are wrong" do
      create(:user, email: "exists@example.com", password: "password123456", password_confirmation: "password123456")

      post user_session_path,
           params: {
             user: { email: "exists@example.com", password: "wrong-password" }
           }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /users/sign_out" do
    it "signs out and redirects" do
      user = create(:user)
      sign_in user

      delete destroy_user_session_path

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Sign in")
    end
  end
end
