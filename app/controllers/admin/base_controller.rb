# frozen_string_literal: true

module Admin
  class BaseController < ActionController::Base
    include Pundit::Authorization

    layout "admin"

    before_action :authenticate_user!
    before_action :require_platform_admin!
    before_action :require_apex_host!
    around_action :without_tenant

    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

    helper_method :admin_nav_items

    private

    def authorize_admin(record, query = nil)
      authorize(record, query, policy_class: Admin::ApplicationPolicy)
    end

    def require_platform_admin!
      return if current_user&.platform_admin?

      redirect_to root_path, alert: t("admin.access.denied")
    end

    def require_apex_host!
      subdomain = request.subdomains.last
      return if subdomain.blank? || subdomain == "www"

      redirect_to admin_root_url(host: apex_host), allow_other_host: true, alert: t("admin.access.apex_only")
    end

    def without_tenant
      ActsAsTenant.without_tenant { yield }
    end

    def user_not_authorized
      redirect_to root_path, alert: t("admin.access.denied")
    end

    def apex_host
      host = Rails.application.config.action_mailer.default_url_options[:host]
      host.in?(%w[localhost 127.0.0.1]) ? "www.lvh.me" : host.delete_prefix("www.")
    end

    def admin_nav_items
      [
        { label: t("admin.nav.dashboard"), path: admin_root_path },
        { label: t("admin.nav.accounts"), path: admin_accounts_path },
        { label: t("admin.nav.plans"), path: admin_plans_path },
        { label: t("admin.nav.features"), path: admin_features_path }
      ]
    end

    def apply_stripe_sync_result(result)
      return if result.success?

      flash[:alert] = t("admin.stripe_sync.failed", error: result.error)
    end
  end
end
