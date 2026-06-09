class Users::RegistrationsController < Devise::RegistrationsController
  include DeviseWorkspaceAuth

  around_action :without_tenant, only: %i[new create]

  def new
    store_pending_checkout_from_params
    super
  end

  def create
    store_pending_checkout_from_params
    build_resource(sign_up_params)

    resource.save
    if resource.persisted?
      Subscriptions::ProvisionFree.call(resource.account)
      WelcomeEmailJob.perform_later(resource.id)
    end

    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        redirect_to_after_auth(after_sign_up_path_for(resource))
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      render :new, status: :unprocessable_content
    end
  end

  def build_resource(hash = {})
    super.tap do |user|
      user.build_account if user.account.nil?
    end
  end

  protected

  def after_sign_up_path_for(resource)
    account = resource.account

    if session[:pending_checkout].present?
      redirect_to_workspace(account, new_stripe_checkout_path)
    else
      workspace_dashboard_url(account)
    end
  end

  def without_tenant
    ActsAsTenant.without_tenant { yield }
  end

  def sign_up_params
    params.require(:user).permit(
      :email, :password, :password_confirmation,
      account_attributes: %i[name subdomain]
    )
  end

  private

  def store_pending_checkout_from_params
    return if params[:plan].blank?

    session[:pending_checkout] = {
      plan_slug: params[:plan],
      interval: params[:interval].presence_in(Price::INTERVALS) || "month"
    }
  end
end
