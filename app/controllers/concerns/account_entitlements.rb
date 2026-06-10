module AccountEntitlements
  extend ActiveSupport::Concern

  private

  def require_feature!(key)
    return if current_user.account.feature_enabled?(key)

    redirect_to dashboard_path, alert: feature_denied_message(key)
  end

  def require_seat_available!
    account = current_user.account
    limit = account.feature_limit(:seats)
    return if limit.nil?

    used = account.users.count + account.invitations.pending.count
    return if used < limit

    redirect_to dashboard_path, alert: t("account_entitlements.seat_limit", count: limit)
  end

  def feature_denied_message(key)
    case key.to_sym
    when :invitations
      t("account_entitlements.invitations_denied")
    else
      t("account_entitlements.feature_denied")
    end
  end
end
