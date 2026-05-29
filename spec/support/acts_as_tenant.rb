RSpec.configure do |config|
  config.after do
    ActsAsTenant.current_tenant = nil
    ActsAsTenant.test_tenant = nil
  end
end
