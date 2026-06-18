# frozen_string_literal: true

module Admin
  class PlansController < BaseController
    before_action :set_plan, only: %i[show edit update destroy]

    def index
      authorize_admin(Plan)
      @plans = Plan.ordered.includes(:prices, plan_features: :feature)
    end

    def show
      authorize_admin(@plan)
    end

    def new
      @plan = Plan.new(status: "draft", position: Plan.maximum(:position).to_i + 1)
      authorize_admin(@plan)
      build_plan_features
    end

    def create
      @plan = Plan.new(plan_params)
      authorize_admin(@plan)

      if @plan.save
        apply_stripe_sync_result(Stripe::CatalogSyncer.sync_plan!(@plan))
        redirect_to admin_plan_path(@plan), notice: t("admin.plans.created")
      else
        build_plan_features
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize_admin(@plan)
      build_plan_features
    end

    def update
      authorize_admin(@plan)

      if @plan.update(plan_params)
        apply_stripe_sync_result(Stripe::CatalogSyncer.sync_plan!(@plan))
        redirect_to admin_plan_path(@plan), notice: t("admin.plans.updated")
      else
        build_plan_features
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize_admin(@plan)

      if Subscription.exists?(price_id: @plan.price_ids)
        redirect_to admin_plans_path, alert: t("admin.plans.destroy_blocked")
        return
      end

      @plan.destroy
      redirect_to admin_plans_path, notice: t("admin.plans.destroyed")
    end

    private

    def set_plan
      @plan = Plan.find(params[:id])
    end

    def plan_params
      params.require(:plan).permit(
        :name, :slug, :description, :status, :position, :highlighted,
        plan_features_attributes: %i[id feature_id enabled limit_value]
      )
    end

    def build_plan_features
      Feature.order(:name).each do |feature|
        next if @plan.plan_features.any? { |pf| pf.feature_id == feature.id }

        @plan.plan_features.build(feature:, enabled: false)
      end
    end
  end
end
