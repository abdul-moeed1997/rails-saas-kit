module ApplicationHelper
  def workspace_domain
    host = Rails.application.config.action_mailer.default_url_options[:host]
    return "lvh.me" if host.in?(%w[localhost 127.0.0.1])

    host.delete_prefix("www.")
  end
end
