module WorkspaceUrlHelpers
  def workspace_url_for(account, path = "/dashboard")
    host = Rails.application.config.action_mailer.default_url_options[:host]
    port = Rails.application.config.action_mailer.default_url_options[:port]
    host_with_port = port ? "#{account.subdomain}.#{host}:#{port}" : "#{account.subdomain}.#{host}"
    "http://#{host_with_port}#{path}"
  end

  def visit_workspace_dashboard!(account)
    host! "#{account.subdomain}.example.com"
    get dashboard_path
  end
end

RSpec.configure do |config|
  config.include WorkspaceUrlHelpers, type: :request
end
