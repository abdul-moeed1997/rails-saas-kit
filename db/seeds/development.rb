# frozen_string_literal: true

return unless Rails.env.development?

dev_email = ENV.fetch("DOCKER_DEV_EMAIL", "admin@acme.com")
dev_password = ENV.fetch("DOCKER_DEV_PASSWORD", "password123456")
dev_subdomain = ENV.fetch("DOCKER_DEV_SUBDOMAIN", "acme")
dev_org_name = ENV.fetch("DOCKER_DEV_ORG_NAME", "Acme Corp")

ActsAsTenant.without_tenant do
  account = Account.find_or_create_by!(subdomain: dev_subdomain) do |record|
    record.name = dev_org_name
  end
  account.update!(name: dev_org_name) if account.name != dev_org_name

  user = User.find_or_initialize_by(email: dev_email)
  user.assign_attributes(
    account: account,
    role: :owner,
    platform_admin: true,
    password: dev_password,
    password_confirmation: dev_password
  )
  user.save!

  Subscriptions::ProvisionFree.call(account)
end

puts ""
puts "Development login ready:"
puts "  Sign in:    http://lvh.me:3000/users/sign_in"
puts "  Workspace:  http://#{dev_subdomain}.lvh.me:3000"
puts "  Admin:      http://lvh.me:3000/admin"
puts "  Email:      #{dev_email}"
puts "  Password:   #{dev_password}"
puts ""
