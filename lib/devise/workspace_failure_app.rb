require "devise/failure_app"

module Devise
  class WorkspaceFailureApp < Devise::FailureApp
    def redirect
      store_location!
      if is_flashing_format?
        if flash[:timedout] && flash[:alert]
          flash.keep(:timedout)
          flash.keep(:alert)
        else
          flash[:alert] = i18n_message
        end
      end

      url = redirect_url
      redirect_to url, allow_other_host: cross_host_redirect?(url)
    end

    def redirect_url
      if WorkspaceAuth.on_workspace_subdomain?(request)
        WorkspaceAuth.apex_sign_in_url(request)
      else
        super
      end
    end

    private

    def cross_host_redirect?(url)
      return false unless url.start_with?("http")

      URI.parse(url).host != request.host
    rescue URI::InvalidURIError
      false
    end
  end
end
