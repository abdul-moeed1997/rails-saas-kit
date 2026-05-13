require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    it "returns success" do
      get root_path
      expect(response).to have_http_status(:ok)
    end

    it "shows sign-in and sign-up when not authenticated" do
      get root_path
      expect(response.body).to include("Sign in", "Sign up")
      expect(response.body).not_to include("Signed in as")
    end

    it "shows the signed-in user email and sign out when authenticated" do
      user = create(:user)
      sign_in user

      get root_path
      expect(response.body).to include("Signed in as", user.email)
      expect(response.body).to include("Sign out")
    end
  end
end
