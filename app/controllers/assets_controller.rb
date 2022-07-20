class AssetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_assetable
  before_action :set_asset, only: [:show, :destroy]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index

  def index
    @assets = Asset.where(assetable: @assetable).build_criteria(params)
    render layout: false
  end

  def create
    asset = Asset.create(
                  assetable: @assetable, 
                  file: params[:files][0], 
                  document_type: params[:document_type], 
                  url: params[:url],
                  booking_portal_client_id: @assetable.booking_portal_client.id
                  )
    if asset.persisted?
      render partial: "assets/asset.json", locals: {asset: asset}
    else
      render json: {errors: asset.errors.full_messages}, status: 406
    end
  end

  def show;  end

  def destroy
    respond_to do |format|
      if @asset.destroy
        format.json {render json: {}, status: :ok}
      else
        format.json {render json: {errors: @asset.errors.full_messages.to_sentence}, status: :unprocessable_entity}
      end
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
    # authorize [current_user_role_group, @assetable] unless %w[index destroy].include?(params[:action])
    if params[:action] == "index"
    elsif params[:action] == "new" || params[:action] == "create"
      authorize [current_user_role_group, Asset.new(assetable: @assetable)]
    else
      authorize [current_user_role_group, @asset]
    end
  end

  def apply_policy_scope
    Asset.with_scope(policy_scope(Asset.all)) do
      yield
    end
  end
end
