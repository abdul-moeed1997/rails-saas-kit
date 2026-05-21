class Users::RegistrationsController < Devise::RegistrationsController
  def build_resource(hash = {})
    super.tap do |user|
      user.build_account if user.account.nil?
    end
  end

  protected

  def sign_up_params
    params.require(:user).permit(
      :email, :password, :password_confirmation,
      account_attributes: %i[name subdomain]
    )
  end
end
