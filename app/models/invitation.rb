class Invitation < ApplicationRecord
  acts_as_tenant :account

  belongs_to :invited_by, class_name: "User"

  has_secure_token

  EXPIRES_IN = 7.days

  validates :email, presence: true, format: { with: Devise.email_regexp }
  validate :email_not_already_on_team, on: :create
  validate :email_not_already_registered, on: :create
  validate :no_duplicate_pending_invite, on: :create

  scope :pending, -> { where(accepted_at: nil).where("expires_at > ?", Time.current) }
  scope :ordered, -> { order(created_at: :desc) }

  before_validation :normalize_email
  before_validation :set_expires_at, on: :create

  def pending?
    accepted_at.nil? && !expired?
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def set_expires_at
    self.expires_at ||= EXPIRES_IN.from_now
  end

  def email_not_already_on_team
    return if email.blank? || account.blank?

    if account.users.where("lower(email) = ?", email).exists?
      errors.add(:email, "is already on your team")
    end
  end

  def email_not_already_registered
    return if email.blank?

    if ActsAsTenant.without_tenant { User.where("lower(email) = ?", email).exists? }
      errors.add(:email, "already has an account—ask them to sign in instead")
    end
  end

  def no_duplicate_pending_invite
    return if email.blank? || account.blank?

    if account.invitations.pending.where("lower(email) = ?", email).where.not(id: id).exists?
      errors.add(:email, "already has a pending invitation")
    end
  end
end
