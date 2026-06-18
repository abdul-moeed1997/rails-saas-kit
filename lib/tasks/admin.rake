namespace :admin do
  desc "Grant platform admin access to a user by email"
  task :grant, [ :email ] => :environment do |_task, args|
    email = args[:email]
    abort 'Usage: bundle exec rails "admin:grant[email@example.com]"' if email.blank?

    user = User.find_by!(email: email)
    user.update!(platform_admin: true)
    puts "Granted platform admin to #{user.email}"
  end
end
