class AssetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_assetable
  before_action :set_asset, only: [:show, :destroy]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index

  def index
    @assets = Asset.where(assetable: @assetable)
    render layout: false
  end

  def create
    asset = Asset.create(assetable: @assetable, file: params[:files][0])
    if asset.persisted?
      render partial: "assets/asset.json", locals: {asset: asset}
    else
      render json: {errors: asset.errors.full_messages}, status: 406
    end
  end

  def show;  end

  def destroy
    @asset.destroy
    respond_to do |format|
      format.json {render json: {}}
    end
  end

  private
  def set_assetable
    @assetable = params[:assetable_type].classify.constantize.find params[:assetable_id]
  end

  def set_asset
    @asset = Asset.where(assetable: @assetable).find params[:id]
  end

  def authorize_resource
    authorize @assetable, :show?
    if params[:action] == "index"
    elsif params[:action] == "new" || params[:action] == "create"
      authorize Asset.new(assetable: @assetable)
    else
      authorize @asset
    end
  end

  def apply_policy_scope
    Asset.with_scope(policy_scope(Asset.all)) do
      yield
    end
  end
end