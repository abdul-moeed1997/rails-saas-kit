class Users::RegistrationsController < Devise::RegistrationsController
  protected

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :account_id)
  end
end
