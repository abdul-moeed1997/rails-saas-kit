require "rails_helper"

RSpec.describe WelcomeEmailJob, type: :job do
  include ActiveJob::TestHelper

  describe "#perform" do
    it "delivers the welcome email" do
      user = create(:user)

      expect {
        described_class.perform_now(user.id)
      }.to change { ActionMailer::Base.deliveries.size }.by(1)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq([ user.email ])
    end

    it "raises when the user no longer exists" do
      expect {
        described_class.perform_now(0)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "queueing" do
    it "uses the mailers queue" do
      user = create(:user)

      expect {
        described_class.perform_later(user.id)
      }.to have_enqueued_job(described_class).on_queue("mailers").with(user.id)
    end
  end
end
