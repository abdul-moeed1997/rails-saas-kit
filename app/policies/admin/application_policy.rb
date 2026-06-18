# frozen_string_literal: true

module Admin
  class ApplicationPolicy
    attr_reader :user, :record

    def initialize(user, record)
      @user = user
      @record = record
    end

    def index?
      platform_admin?
    end

    def show?
      platform_admin?
    end

    def create?
      platform_admin?
    end

    def new?
      create?
    end

    def update?
      platform_admin?
    end

    def edit?
      update?
    end

    def destroy?
      platform_admin?
    end

    def reset_subscription?
      platform_admin?
    end

    class Scope
      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve
        scope.all
      end

      private

      attr_reader :user, :scope
    end

    private

    def platform_admin?
      user&.platform_admin?
    end
  end
end
