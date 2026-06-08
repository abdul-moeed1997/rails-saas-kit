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

    redirect_to dashboard_path, alert: "Your plan allows up to #{limit} #{"seat".pluralize(limit)}. Upgrade to invite more teammates."
  end

  def feature_denied_message(key)
    case key.to_sym
    when :invitations
      "Team invitations are not included in your current plan. Upgrade to invite teammates."
    else
      "This feature is not included in your current plan."
    end
  end
end
