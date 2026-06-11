class ApplicationController < ActionController::Base
  include Pundit::Authorization

  set_current_tenant_by_subdomain(:account, :subdomain)
  include WorkspaceSubdomain
  include Locale

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  def after_sign_in_path_for(resource)
    destination = stored_location_for(resource) || dashboard_path
    redirect_to_workspace(resource.account, destination)
  end

  private

  def user_not_authorized
    redirect_to dashboard_path, alert: t("pundit.not_authorized")
  end
end
