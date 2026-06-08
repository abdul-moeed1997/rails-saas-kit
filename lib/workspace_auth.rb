module WorkspaceAuth
  module_function

  def workspace_subdomain_from(request)
    subdomain = request.subdomains.last
    return if subdomain.blank?
    return if subdomain == "www"

    subdomain
  end

  def on_workspace_subdomain?(request)
    workspace_subdomain_from(request).present?
  end

  def apex_host
    host = Rails.application.config.action_mailer.default_url_options[:host]
    return "lvh.me" if host.in?(%w[localhost 127.0.0.1])

    host.delete_prefix("www.")
  end

  def apex_sign_in_url(request)
    url_host = apex_host
    url_host = "#{url_host}:#{request.port}" unless request.port.in?([ 80, 443 ])
    "#{request.protocol}#{url_host}/users/sign_in"
  end
end
