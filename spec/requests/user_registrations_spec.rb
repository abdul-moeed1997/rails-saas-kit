require "rails_helper"

RSpec.describe "User registrations", type: :request do
  include ActiveJob::TestHelper

  before { load_billing_catalog! }

  describe "POST /users" do
    it "creates an organization and admin user, then redirects to root (signed in)" do
      expect do
        post user_registration_path,
             params: {
               user: {
                 email: "founder@acme.com",
                 password: "password123456",
                 password_confirmation: "password123456",
                 account_attributes: {
                   name: "Acme Corp",
                   subdomain: "acme"
                 }
               }
             }
      end.to change(User, :count).by(1)
        .and change(Account, :count).by(1)
        .and have_enqueued_job(WelcomeEmailJob)

      user = User.last
      expect(WelcomeEmailJob).to have_been_enqueued.with(user.id)
      expect(user.account).to have_attributes(name: "Acme Corp", subdomain: "acme")
      expect(user.email).to eq("founder@acme.com")
      expect(user.account.subscription).to be_present
      expect(user.account.subscription.plan.slug).to eq("free")

      expect(response).to redirect_to(workspace_url_for(user.account))
      visit_workspace_dashboard!(user.account)
      expect(response.body).to include("Dashboard", "founder@acme.com")
    end

    it "does not create a user without organization details" do
      expect do
        post user_registration_path,
             params: {
               user: {
                 email: "orphan@example.com",
                 password: "password123456",
                 password_confirmation: "password123456"
               }
             }
      end.not_to change(User, :count)

      expect(WelcomeEmailJob).not_to have_been_enqueued
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "does not let a user join an existing account via account_id" do
      existing_account = create(:account)

      expect do
        post user_registration_path,
             params: {
               user: {
                 account_id: existing_account.id,
                 email: "intruder@example.com",
                 password: "password123456",
                 password_confirmation: "password123456",
                 account_attributes: {
                   name: "Other Corp",
                   subdomain: "other"
                 }
               }
             }
      end.to change(User, :count).by(1).and change(Account, :count).by(1)

      expect(User.last.account).not_to eq(existing_account)
    end

    it "redirects to checkout after signup when a paid plan was selected" do
      pro_monthly_price.update!(stripe_price_id: "price_pro_month")

      allow(Stripe::Customer).to receive(:create).and_return(
        Stripe::Customer.construct_from(id: "cus_new")
      )
      allow(Stripe::Checkout::Session).to receive(:create).and_return(
        Stripe::Checkout::Session.construct_from(url: "https://checkout.stripe.com/test")
      )

      post user_registration_path,
           params: {
             user: {
               email: "founder@acme.com",
               password: "password123456",
               password_confirmation: "password123456",
               account_attributes: {
                 name: "Acme Corp",
                 subdomain: "acme"
               }
             },
             plan: "pro",
             interval: "month"
           }

      user = User.last
      expect(response).to redirect_to(workspace_url_for(user.account, new_stripe_checkout_path))

      host! "acme.example.com"
      get new_stripe_checkout_path
      expect(response).to have_http_status(:ok)

      post stripe_checkout_path, params: { plan_slug: "pro", interval: "month" }
      expect(response).to redirect_to("https://checkout.stripe.com/test")
    end

    it "re-renders sign up with errors when params are invalid" do
      expect do
        post user_registration_path,
             params: {
               user: {
                 email: "",
                 password: "short",
                 password_confirmation: "nomatch",
                 account_attributes: {
                   name: "",
                   subdomain: ""
                 }
               }
             }
      end.not_to change(User, :count)

      expect(WelcomeEmailJob).not_to have_been_enqueued
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /users/sign_up when already signed in" do
    it "redirects away from the registration form" do
      user = create(:user)
      sign_in user
      get new_user_registration_path
      expect(response).to redirect_to(workspace_url_for(user.account))
    end
  end

  describe "password reset email delivery" do
    it "enqueues or delivers reset instructions matching production mailer setup",
       skip: "add mailer or system spec; assert ActionMailer::Base.deliveries when reset is triggered" do
    end
  end
end
