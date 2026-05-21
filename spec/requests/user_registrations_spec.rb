require "rails_helper"

RSpec.describe "User registrations", type: :request do
  describe "POST /users" do
    it "creates a user and redirects to root (signed in)" do
      account = create(:account)

      expect do
        post user_registration_path,
             params: {
               user: {
                 account_id: account.id,
                 email: "newbie@example.com",
                 password: "password123456",
                 password_confirmation: "password123456"
               }
             }
      end.to change(User, :count).by(1)

      expect(User.last.account).to eq(account)

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("newbie@example.com")
    end

    it "does not create a user without an account" do
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

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "re-renders sign up with errors when params are invalid" do
      expect do
        post user_registration_path,
             params: {
               user: {
                 email: "",
                 password: "short",
                 password_confirmation: "nomatch"
               }
             }
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /users/sign_up when already signed in" do
    it "redirects away from the registration form" do
      sign_in create(:user)
      get new_user_registration_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "password reset email delivery" do
    it "enqueues or delivers reset instructions matching production mailer setup",
       skip: "add mailer or system spec; assert ActionMailer::Base.deliveries when reset is triggered" do
    end
  end
end
