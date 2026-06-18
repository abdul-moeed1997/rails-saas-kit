# frozen_string_literal: true

module Admin
  class AccountsController < BaseController
    PER_PAGE = 25

    before_action :set_account, only: %i[show edit update reset_subscription]

    def index
      authorize_admin(Account)
      @page = [ params[:page].to_i, 1 ].max
      @accounts = filtered_accounts
    end

    def show
      authorize_admin(@account)
      @users = @account.users.order(:email)
      @subscription = @account.subscription
    end

    def edit
      authorize_admin(@account)
    end

    def update
      authorize_admin(@account)

      if @account.update(account_params)
        redirect_to admin_account_path(@account), notice: t("admin.accounts.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def reset_subscription
      authorize_admin(@account, :reset_subscription?)

      subscription = @account.subscription || Subscriptions::ProvisionFree.call(@account)
      Subscriptions::ProvisionFree.reset_to_free!(subscription)
      redirect_to admin_account_path(@account), notice: t("admin.accounts.subscription_reset")
    end

    private

    def set_account
      @account = Account.find(params[:id])
    end

    def account_params
      params.require(:account).permit(:name, :subdomain)
    end

    def filtered_accounts
      scope = Account.includes(:users, subscription: { price: :plan }).order(:name)

      if params[:q].present?
        query = "%#{Account.sanitize_sql_like(params[:q])}%"
        scope = scope.where("accounts.name ILIKE :q OR accounts.subdomain ILIKE :q", q: query)
      end

      page = @page || [ params[:page].to_i, 1 ].max
      scope.offset((page - 1) * PER_PAGE).limit(PER_PAGE)
    end
  end
end
