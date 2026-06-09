require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  describe "#welcome" do
    it "builds the dashboard URL with the account subdomain and app domain" do
      account = create(:account, name: "Acme Corp", subdomain: "acme")
      user = create(:user, account: account, email: "founder@acme.com")

      mail = described_class.welcome(user)

      expect(mail.to).to eq([ "founder@acme.com" ])
      expect(mail.subject).to include("Acme Corp")
      expect(mail.body.encoded).to include("http://acme.example.com/dashboard")
    end
  end
end
