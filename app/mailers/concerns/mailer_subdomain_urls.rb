module MailerSubdomainUrls
  extend ActiveSupport::Concern

  private

  def workspace_url_options(account)
    options = Rails.application.config.action_mailer.default_url_options.dup
    options[:host] = "#{account.subdomain}.#{base_host}"
    options
  end

  def base_host
    host = Rails.application.config.action_mailer.default_url_options[:host]
    return "lvh.me" if host.in?(%w[localhost 127.0.0.1])

    host.delete_prefix("www.")
  end
end
