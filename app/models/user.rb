class User < ApplicationRecord
  include Roleable

  acts_as_tenant :account
  accepts_nested_attributes_for :account

  has_many :sent_invitations, class_name: "Invitation", foreign_key: :invited_by_id, dependent: :destroy, inverse_of: :invited_by

  validates :locale, inclusion: { in: ->(_) { I18n.available_locales.map(&:to_s) } }, allow_nil: true

  before_validation :assign_owner_role_for_new_account, on: :create

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  def self.find_for_authentication(conditions)
    ActsAsTenant.without_tenant { super(conditions) }
  end

  def self.serialize_from_session(key, salt)
    ActsAsTenant.without_tenant { super(key, salt) }
  end

  private

  def assign_owner_role_for_new_account
    self.role = :owner if account&.new_record?
  end
end
