require "rails_helper"

RSpec.describe "Admin access", type: :request do
  describe "GET /admin" do
    it "redirects guests to sign in" do
      get admin_root_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "denies non-platform admins" do
      user = create(:user)
      sign_in user

      get admin_root_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("admin.access.denied"))
    end

    it "allows platform admins" do
      user = create(:user, :platform_admin)
      sign_in user

      get admin_root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("admin.dashboard.title"))
    end

    it "redirects from workspace subdomain to apex admin" do
      user = create(:user, :platform_admin)
      sign_in user
      host! "#{user.account.subdomain}.example.com"

      get admin_root_path
      expect(response).to redirect_to(admin_root_url(host: "example.com"))
    end
  end
end
