class PublicAssetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_public_assetable
  before_action :set_asset, only: [:show, :destroy]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: :index

  def index
    @public_assets = PublicAsset.where(public_assetable: @public_assetable).build_criteria(params)
    render layout: false
  end

  def create
    public_asset = PublicAsset.create(
                                    public_assetable: @public_assetable,
                                    file: params[:files][0],
                                    document_type: params[:document_type],
                                    booking_portal_client_id: current_client.id
                                    )
    if public_asset.persisted?
      render partial: "assets/asset.json", locals: {asset: public_asset}
    else
      render json: {errors: public_asset.errors.full_messages}, status: 406
    end
  end

  def show;  end

  def destroy
    respond_to do |format|
      if @public_asset.destroy
        format.json {render json: {}, status: :ok}
      else
        format.json {render json: {errors: @public_asset.errors.full_messages.to_sentence}, status: :unprocessable_entity}
      end
    end
  end

  private
  def set_public_assetable
    @public_assetable = params[:public_assetable_type].classify.constantize.where(id: params[:public_assetable_id]).first
  end

  def set_asset
    @public_asset = PublicAsset.where(public_assetable: @public_assetable, id: params[:id]).first
  end

  def authorize_resource
    # authorize [current_user_role_group, @assetable] unless %w[index destroy].include?(params[:action])
    if params[:action] == "index"
    elsif params[:action] == "new" || params[:action] == "create"
      authorize [current_user_role_group, PublicAsset.new(public_assetable: @public_assetable)]
    else
      authorize [current_user_role_group, @public_asset]
    end
  end

  def apply_policy_scope
    PublicAsset.with_scope(policy_scope(PublicAsset.all)) do
      yield
    end
  end
end
