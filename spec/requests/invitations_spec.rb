require "rails_helper"

RSpec.describe "Invitations", type: :request do
  before { load_billing_catalog! }

  let(:account) { create(:account, name: "Acme Corp", subdomain: "acme") }
  let(:founder) { create(:user, account: account, email: "founder@acme.com") }

  describe "POST /invitations" do
    before do
      create_pro_subscription(account)
      sign_in founder
    end

    it "sends an invitation email and shows it on the dashboard" do
      expect do
        post invitations_path, params: { invitation: { email: "teammate@example.com" } }
      end.to change(Invitation, :count).by(1)
        .and change { ActionMailer::Base.deliveries.size }.by(1)

      invitation = Invitation.last
      expect(invitation).to have_attributes(
        email: "teammate@example.com",
        account: account,
        invited_by: founder
      )

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq([ "teammate@example.com" ])
      expect(mail.body.encoded).to include("founder@acme.com", "Acme Corp", "acme.example.com")

      expect(response).to redirect_to(dashboard_path)
      visit_workspace_dashboard!(account)
      expect(response.body).to include("teammate@example.com", "Pending invitations")
    end

    it "re-renders the form when the email is invalid" do
      post invitations_path, params: { invitation: { email: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Invite a teammate")
    end

    it "does not invite an existing teammate" do
      create(:user, account: account, email: "member@acme.com")

      expect do
        post invitations_path, params: { invitation: { email: "member@acme.com" } }
      end.not_to change(Invitation, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /invitations/:id" do
    before do
      create_pro_subscription(account)
      sign_in founder
    end

    it "cancels a pending invitation" do
      invitation = create(:invitation, account: account, invited_by: founder, email: "pending@example.com")

      expect do
        delete invitation_path(invitation)
      end.to change(Invitation, :count).by(-1)

      follow_redirect!
      expect(response.body).not_to include("pending@example.com")
    end
  end

  describe "GET /invitations/new" do
    it "requires authentication" do
      get new_invitation_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "blocks invitations on the free plan" do
      ActsAsTenant.with_tenant(account) do
        create(:subscription, account: account, price: free_price, status: "active")
      end
      sign_in founder
      host! "acme.example.com"

      get new_invitation_path

      expect(response).to redirect_to(dashboard_path)
      visit_workspace_dashboard!(account)
      expect(response.body).to include("not included in your current plan")
    end
  end
end
