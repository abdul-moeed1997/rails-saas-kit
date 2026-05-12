ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

RSpec.describe "RSpec setup" do
  it "loads the Rails test environment" do
    expect(Rails.env).to eq("test")
    expect(Rails.application).to be_present
  end
end
