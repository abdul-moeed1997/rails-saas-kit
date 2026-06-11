require "rails_helper"

RSpec.describe "Invitation acceptances", type: :request do
  before { load_billing_catalog! }

  let(:password) { "password123456" }
  let(:account) { create(:account, name: "Acme Corp", subdomain: "acme") }
  let(:founder) { create(:user, account: account, email: "founder@acme.com") }
  let(:invitation) { create(:invitation, account: account, invited_by: founder, email: "teammate@example.com") }

  describe "GET /invitations/:token/accept" do
    it "shows the accept invitation form" do
      get accept_invitation_path(invitation.token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Join Acme Corp", "teammate@example.com", "Accept invitation")
    end

    it "redirects when the invitation was already accepted" do
      invitation.update!(accepted_at: Time.current)

      get accept_invitation_path(invitation.token)

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("already been accepted")
    end

    it "redirects when the invitation expired" do
      invitation.update!(expires_at: 1.day.ago)

      get accept_invitation_path(invitation.token)

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("expired")
    end

    it "redirects when the invitation was cancelled" do
      token = invitation.token
      invitation.destroy!

      get accept_invitation_path(token)

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("cancelled", "no longer valid")
    end
  end

  describe "POST /invitations/:token/accept" do
    it "creates the user, accepts the invitation, and signs them in" do
      post accept_invitation_path(invitation.token),
           params: {
             user: {
               password: password,
               password_confirmation: password
             }
           }

      teammate = User.find_by!(email: "teammate@example.com")
      expect(teammate.account).to eq(account)
      expect(teammate).to be_member
      expect(ActsAsTenant.without_tenant { invitation.reload.accepted_at }).to be_present

      expect(response).to redirect_to(workspace_url_for(account))
      visit_workspace_dashboard!(account)
      expect(response.body).to include("Welcome to Acme Corp", "teammate@example.com")
    end

    it "re-renders the form when the password is invalid" do
      post accept_invitation_path(invitation.token),
           params: {
             user: {
               password: "short",
               password_confirmation: "nomatch"
             }
           }

      expect(response).to have_http_status(:unprocessable_content)
      expect(invitation.reload.accepted_at).to be_nil
    end

    it "redirects when the invitation was cancelled" do
      token = invitation.token
      invitation.destroy!

      post accept_invitation_path(token),
           params: {
             user: {
               password: password,
               password_confirmation: password
             }
           }

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("cancelled", "no longer valid")
      expect(User.find_by(email: "teammate@example.com")).to be_nil
    end

    it "blocks invitation acceptance when the seat limit is reached" do
      create_pro_subscription(account)
      create(:user, account: account, email: "member@acme.com")
      8.times do |index|
        create(:invitation, account: account, invited_by: founder, email: "pending#{index}@example.com")
      end

      post accept_invitation_path(invitation.token),
           params: {
             user: {
               password: password,
               password_confirmation: password
             }
           }

      expect(response).to redirect_to(root_path)
      expect(User.find_by(email: "teammate@example.com")).to be_nil
    end

    it "accepts an invitation when the workspace is at its seat limit from pending invites" do
      create_pro_subscription(account)
      create(:user, account: account, email: "member@acme.com")
      7.times do |index|
        create(:invitation, account: account, invited_by: founder, email: "pending#{index}@example.com")
      end

      post accept_invitation_path(invitation.token),
           params: {
             user: {
               password: password,
               password_confirmation: password
             }
           }

      expect(response).to redirect_to(workspace_url_for(account))
      expect(User.find_by!(email: "teammate@example.com").account).to eq(account)
      expect(ActsAsTenant.without_tenant { invitation.reload.accepted_at }).to be_present
    end
  end
end
