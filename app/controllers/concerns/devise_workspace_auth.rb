module DeviseWorkspaceAuth
  extend ActiveSupport::Concern

  protected

  def require_no_authentication
    assert_is_devise_resource!
    return unless is_navigational_format?

    authenticated = if devise_mapping.no_input_strategies.present?
      warden.authenticate?(*devise_mapping.no_input_strategies.dup.push(scope: resource_name))
    else
      warden.authenticated?(resource_name)
    end

    if authenticated && (resource = warden.user(resource_name))
      set_flash_message(:alert, "already_authenticated", scope: "devise.failure")
      redirect_to_after_auth(after_sign_in_path_for(resource))
    end
  end
end
