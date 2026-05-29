require "rails_helper"

RSpec.describe InvitationMailer, type: :mailer do
  describe "#invite" do
    it "builds the accept URL with the account subdomain and app domain" do
      account = create(:account, subdomain: "acme")
      founder = create(:user, account: account)
      invitation = create(:invitation, account: account, invited_by: founder, email: "teammate@example.com")

      mail = described_class.invite(invitation)

      expect(mail.body.encoded).to include("http://acme.example.com/invitations/#{invitation.token}/accept")
    end
  end
end
