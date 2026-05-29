class Users::RegistrationsController < Devise::RegistrationsController
  around_action :without_tenant, only: %i[new create]

  def build_resource(hash = {})
    super.tap do |user|
      user.build_account if user.account.nil?
    end
  end

  protected

  def without_tenant
    ActsAsTenant.without_tenant { yield }
  end

  def sign_up_params
    params.require(:user).permit(
      :email, :password, :password_confirmation,
      account_attributes: %i[name subdomain]
    )
  end
end
