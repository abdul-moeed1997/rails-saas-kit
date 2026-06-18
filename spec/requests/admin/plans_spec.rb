require "rails_helper"

RSpec.describe "Admin plans", type: :request do
  let(:admin) { create(:user, :platform_admin) }

  before do
    load_billing_catalog!
    sign_in admin
  end

  describe "GET /admin/plans" do
    it "lists plans" do
      get admin_plans_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Free", "Pro", "Business")
    end
  end

  describe "POST /admin/plans" do
    it "creates a plan" do
      allow(Stripe::Product).to receive(:create).and_return(
        Stripe::Product.construct_from(id: "prod_new")
      )

      post admin_plans_path, params: {
        plan: {
          name: "Enterprise",
          slug: "enterprise",
          description: "For large teams",
          status: "draft",
          position: 3,
          highlighted: false
        }
      }

      expect(response).to redirect_to(admin_plan_path(Plan.find_by!(slug: "enterprise")))
      expect(Plan.find_by!(slug: "enterprise").name).to eq("Enterprise")
    end
  end

  describe "PATCH /admin/plans/:id" do
    it "updates plan entitlements" do
      plan = Plan.find_by_slug!("pro")
      plan_feature = plan.plan_features.joins(:feature).find_by!(features: { key: "sso" })

      patch admin_plan_path(plan), params: {
        plan: {
          name: plan.name,
          slug: plan.slug,
          description: plan.description,
          status: plan.status,
          position: plan.position,
          highlighted: plan.highlighted,
          plan_features_attributes: {
            "0" => { id: plan_feature.id, feature_id: plan_feature.feature_id, enabled: true, limit_value: nil }
          }
        }
      }

      expect(response).to redirect_to(admin_plan_path(plan))
      expect(plan_feature.reload.enabled).to be(true)
    end
  end
end
