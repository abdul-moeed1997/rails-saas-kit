class Users::SessionsController < Devise::SessionsController
  include DeviseWorkspaceAuth

  around_action :without_tenant, only: %i[new create]
  before_action :redirect_sign_in_to_apex, only: :new

  def create
    self.resource = warden.authenticate!(auth_options)
    set_flash_message!(:notice, :signed_in) if is_navigational_format?
    sign_in(resource_name, resource)
    yield resource if block_given?
    redirect_to_after_auth(after_sign_in_path_for(resource))
  end

  private

  def without_tenant
    ActsAsTenant.without_tenant { yield }
  end

  def redirect_sign_in_to_apex
    return if workspace_subdomain_from_request.blank?

    redirect_to WorkspaceAuth.apex_sign_in_url(request), allow_other_host: true
  end
end
