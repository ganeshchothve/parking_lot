class Admin::ClientsController < AdminController
  before_action :set_client
  before_action :authorize_resource
  layout :set_layout

  def edit
    render layout: false
  end


  #
  # This download_brochure action for Admin users where brochure download will start.
  #
  # GET /admin/clients/download_brochure
  #
  def download_brochure
    send_file(@client.brochure.path,
          :filename => @client.brochure.url,
          :type => @client.brochure.content_type,
          :disposition => 'attachment',
          :url_based_filename => true)
    current_user.portal_stage << PortalStage.new(stage: 'project_info') if current_user.buyer? && current_user.receipts.count == 0
  end

  def update
    @client.assign_attributes(permitted_attributes([:admin, @client]))
    respond_to do |format|
      if @client.save
        format.html { redirect_back fallback_location: root_path, notice: 'Client successfully updated.' }
        format.json { render json: @client }
      else
        format.html { render :edit }
        format.json { render json: {errors: @client.errors.full_messages}, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_client
    @client = current_client
  end

  def authorize_resource
    authorize [:admin, @client]
  end
end
