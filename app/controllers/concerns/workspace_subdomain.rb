module WorkspaceSubdomain
  extend ActiveSupport::Concern

  included do
    before_action :require_valid_workspace_subdomain
    before_action :redirect_signed_in_user_to_workspace
  end

  private

  def require_valid_workspace_subdomain
    return if devise_controller?

    subdomain = workspace_subdomain_from_request
    return if subdomain.blank?

    tenant = ActsAsTenant.current_tenant
    if tenant.nil?
      render "errors/workspace_not_found", status: :not_found, layout: "application"
      return
    end

    if user_signed_in? && current_user.account_id != tenant.id
      redirect_to workspace_dashboard_url(current_user.account), allow_other_host: true
    end
  end

  def redirect_signed_in_user_to_workspace
    return unless user_signed_in?
    return if workspace_subdomain_from_request.present?
    return unless request.get?
    return if devise_controller?
    return unless action_requires_authentication?

    redirect_to workspace_url_for(current_user.account, request.fullpath), allow_other_host: true
  end

  def action_requires_authentication?
    self.class._process_action_callbacks.map(&:filter).include?(:authenticate_user!)
  end

  def workspace_subdomain_from_request
    subdomain = request.subdomains.last
    return if subdomain.blank?
    return if subdomain == "www"

    subdomain
  end

  def redirect_to_workspace(account, path = dashboard_path)
    if workspace_subdomain_from_request.blank? || workspace_subdomain_from_request != account.subdomain
      workspace_url_for(account, path)
    else
      path
    end
  end

  def redirect_to_after_auth(url)
    redirect_to url, allow_other_host: cross_host_redirect?(url)
  end

  def cross_host_redirect?(url)
    return false unless url.start_with?("http")

    URI.parse(url).host != request.host
  rescue URI::InvalidURIError
    false
  end

  def workspace_dashboard_url(account)
    workspace_url_for(account, dashboard_path)
  end

  def workspace_url_for(account, path)
    path = extract_path(path)
    options = workspace_url_options(account)
    host = options[:host]
    host = "#{host}:#{options[:port]}" if options[:port]
    "#{request.protocol}#{host}#{path}"
  end

  def workspace_url_options(account)
    Rails.application.config.action_mailer.default_url_options.dup.tap do |options|
      options[:host] = "#{account.subdomain}.#{workspace_base_host}"
    end
  end

  def extract_path(path)
    return path if path.start_with?("/")

    uri = URI.parse(path)
    path_with_query = uri.path
    path_with_query += "?#{uri.query}" if uri.query
    path_with_query
  end

  def workspace_base_host
    host = Rails.application.config.action_mailer.default_url_options[:host]
    return "lvh.me" if host.in?(%w[localhost 127.0.0.1])

    host.delete_prefix("www.")
  end
end
