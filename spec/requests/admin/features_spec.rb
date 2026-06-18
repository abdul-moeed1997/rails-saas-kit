require "rails_helper"

RSpec.describe "Admin features", type: :request do
  let(:admin) { create(:user, :platform_admin) }

  before do
    load_billing_catalog!
    sign_in admin
  end

  describe "GET /admin/features" do
    it "lists features" do
      get admin_features_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Team seats", "seats")
    end
  end

  describe "POST /admin/features" do
    it "creates a feature" do
      post admin_features_path, params: {
        feature: { key: "api_access", name: "API access", description: "REST API access" }
      }

      expect(response).to redirect_to(admin_features_path)
      expect(Feature.find_by!(key: "api_access").name).to eq("API access")
    end
  end
end
