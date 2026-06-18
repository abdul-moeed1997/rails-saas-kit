# frozen_string_literal: true

module Admin
  class FeaturesController < BaseController
    before_action :set_feature, only: %i[edit update destroy]

    def index
      authorize_admin(Feature)
      @features = Feature.order(:name)
    end

    def new
      @feature = Feature.new
      authorize_admin(@feature)
    end

    def create
      @feature = Feature.new(feature_params)
      authorize_admin(@feature)

      if @feature.save
        redirect_to admin_features_path, notice: t("admin.features.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize_admin(@feature)
    end

    def update
      authorize_admin(@feature)

      if @feature.update(feature_params)
        redirect_to admin_features_path, notice: t("admin.features.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize_admin(@feature)

      if @feature.plan_features.exists?
        redirect_to admin_features_path, alert: t("admin.features.destroy_blocked")
        return
      end

      @feature.destroy
      redirect_to admin_features_path, notice: t("admin.features.destroyed")
    end

    private

    def set_feature
      @feature = Feature.find(params[:id])
    end

    def feature_params
      params.require(:feature).permit(:key, :name, :description)
    end
  end
end
