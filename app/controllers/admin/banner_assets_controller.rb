class Admin::BannerAssetsController < ApplicationController
  before_action :set_banner_asset, only: [:edit, :update, :destroy]
  before_action :authorize_resource

  def index
    @banner_assets = BannerAsset.all.order('created_at DESC')
    @banner_assets = @banner_assets.paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.json { render json: @banner_assets }
      format.html {}
    end
  end

  def new
    @banner_asset = BannerAsset.new
    render layout: false
  end

  def create
    @banner_asset = BannerAsset.new(banner_image: params["banner_asset"]["banner_image"], mobile_banner_image: params["banner_asset"]["mobile_banner_image"], url: params["banner_asset"]["url"], uploaded_by: current_user)
    @banner_asset.assign_attributes(permitted_attributes([:admin, @banner_asset]))
    respond_to do |format|
      if @banner_asset.save
        format.html { redirect_to admin_banner_assets_path, notice: "Banner Image Upload Successfull" }
        format.json { render json: @banner_asset, status: :created }
      else
        format.html { redirect_to admin_banner_assets_path, alert: "Banner Image Upload Unsuccessfull" }
        format.json { render json: { errors: @banner_asset.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def edit
    render layout: false
  end

  def update
    @banner_asset.assign_attributes(permitted_attributes([:admin, @banner_asset]))
    respond_to do |format|
      if @banner_asset.save
        format.html { redirect_to admin_banner_assets_path, notice: "Banner Image Update Successfull" }
        format.json { render json: @banner_asset, status: :created }
      else
        format.html { redirect_to admin_banner_assets_path, alert: "Banner Image Update Unsuccessfull" }
        format.json { render json: { errors: @banner_asset.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @banner_asset.destroy
        format.json {render json: {}, status: :ok}
        format.html { redirect_to admin_banner_assets_path, notice: "Banner Image Deleted Successfully" }
      else
        format.json {render json: {errors: @banner_asset.errors.full_messages.to_sentence}, status: :unprocessable_entity}
        format.html { redirect_to admin_banner_assets_path, alert: @banner_asset.errors.full_messages.uniq }
      end
    end
  end

  private

  def authorize_resource
    if params[:action] == 'index'
      authorize [:admin, BannerAsset]
    elsif params[:action] == 'new'
      authorize [:admin, BannerAsset.new]
    elsif params[:action] == 'create'
      authorize [:admin, BannerAsset.new(permitted_attributes([:admin, BannerAsset.new]))]
    else
      authorize [:admin, @banner_asset]
    end
  end

  def set_banner_asset
    @banner_asset = BannerAsset.find(params[:id])
  end
end
