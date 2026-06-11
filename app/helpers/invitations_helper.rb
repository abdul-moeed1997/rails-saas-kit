module InvitationsHelper
  INVITE_BUTTON_ENABLED_CLASSES =
    "inline-flex justify-center rounded-lg bg-indigo-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"

  INVITE_BUTTON_DISABLED_CLASSES =
    "inline-flex justify-center rounded-lg bg-zinc-200 px-4 py-2.5 text-sm font-semibold text-zinc-400 shadow-sm cursor-not-allowed select-none"

  def invite_teammates_available?
    account = current_user.account
    invitation = Invitation.new(account: account)

    policy(invitation).create? && seats_available_for_invite?(account)
  end

  def invite_teammates_button_classes
    invite_teammates_available? ? INVITE_BUTTON_ENABLED_CLASSES : INVITE_BUTTON_DISABLED_CLASSES
  end

  private

  def seats_available_for_invite?(account)
    limit = account.feature_limit(:seats)
    return true if limit.nil?

    used = account.users.count + account.invitations.pending.count
    used < limit
  end
end
