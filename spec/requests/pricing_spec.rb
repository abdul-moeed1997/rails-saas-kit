require "rails_helper"

RSpec.describe "Pricing", type: :request do
  before { load Rails.root.join("db/seeds.rb") }

  describe "GET /pricing" do
    it "returns success" do
      get pricing_path
      expect(response).to have_http_status(:ok)
    end

    it "displays plan tiers from the catalog" do
      get pricing_path

      expect(response.body).to include("Free", "Pro", "Business")
      expect(response.body).to include("Most popular")
      expect(response.body).to include("Compare all features")
      expect(response.body).to include("Team seats")
    end

    it "shows sign up CTAs when not authenticated" do
      get pricing_path

      expect(response.body).to include("Get started free", "Start free trial", "Simple, transparent pricing")
    end

    it "shows upgrade CTAs when authenticated" do
      user = create(:user)
      sign_in user

      get pricing_path

      expect(response.body).to include("Upgrade")
      expect(response.body).not_to include("Get started free")
    end
  end
end
