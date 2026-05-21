require "rails_helper"

RSpec.describe "SaaS onboarding flow", type: :request do
  let(:password) { "password123456" }

  it "completes organization signup, session, dashboard access, sign out, and sign in" do
    # Guest lands on marketing home
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("You are not signed in", "Sign in", "Sign up")

    # Guest opens organization signup
    get new_user_registration_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Create your organization", "Organization name", "Workspace URL")

    # Founder creates organization + admin user
    expect do
      post user_registration_path,
           params: {
             user: {
               email: "founder@acme.com",
               password: password,
               password_confirmation: password,
               account_attributes: {
                 name: "Acme Corp",
                 subdomain: "acme"
               }
             }
           }
    end.to change(Account, :count).by(1).and change(User, :count).by(1)

    founder = User.find_by!(email: "founder@acme.com")
    expect(founder.account).to have_attributes(name: "Acme Corp", subdomain: "acme")

    expect(response).to redirect_to(root_path)
    follow_redirect!
    expect(response.body).to include("Signed in as", "founder@acme.com")

    # Authenticated founder reaches protected dashboard
    get dashboard_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Dashboard", "founder@acme.com")

    # Founder signs out
    delete destroy_user_session_path
    expect(response).to redirect_to(root_path)
    follow_redirect!
    expect(response.body).to include("You are not signed in", "Sign in")

    # Signed-out user cannot access dashboard
    get dashboard_path
    expect(response).to redirect_to(new_user_session_path)

    # Founder signs back in (Devise returns to the previously requested dashboard)
    post user_session_path,
         params: {
           user: { email: "founder@acme.com", password: password }
         }
    expect(response).to redirect_to(dashboard_path)
    follow_redirect!
    expect(response.body).to include("Dashboard", "founder@acme.com")
  end

  it "allows a second user to belong to the same organization" do
    account = create(:account, name: "Acme Corp", subdomain: "acme")
    founder = create(:user, account: account, email: "founder@acme.com")
    teammate = create(:user, account: account, email: "teammate@acme.com")

    expect(account.users).to contain_exactly(founder, teammate)
    expect(founder.account_id).to eq(teammate.account_id)
  end
end
