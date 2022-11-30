class Admin::ClientsController < AdminController
  before_action :set_client
  before_action :authorize_resource
  layout :set_layout

  def edit
    render layout: false
  end

  def kylas_api_key
  end

  def update
    @client.assign_attributes(permitted_attributes([:admin, @client]))
    respond_to do |format|
      if @client.save
        format.html { redirect_to root_path, notice: 'Client successfully updated.' }
        format.json { render json: @client }
      else
        format.html { render (params[:render_kylas_api_key] ? :kylas_api_key : :edit) }
        format.json { render json: {errors: @client.errors.full_messages.flatten}, status: :unprocessable_entity }
      end
    end
  end

  def show
    respond_to do |format|
      format.json { render json: @client.as_json({only: [:_id,:name], include: {regions: {only: [:_id, :city, :partner_regions]}}}) }
      format.html {}
    end
  end

  def get_regions
    @regions = @client.regions
    @regions = @regions.where(city: params[:city]) if params[:city]
  end

  private

  def set_client
    @client = current_client
  end

  def authorize_resource
    authorize [:admin, @client]
  end
end
