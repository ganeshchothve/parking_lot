class DashboardController < ApplicationController
  before_action :authenticate_user!, only: [:index, :documents]
  layout :set_layout

  def index
    authorize :dashboard, :index?
    @project_units = current_user.project_units
  end

  def faqs
  end

  def documents
    @assetable = current_client
  end

  def rera
  end

  def tds_process
  end

  def terms_and_conditions
  end

  def gamify_unit_selection
    data = ProjectUnit.build_criteria({
      fltrs: {
        status: ProjectUnit.booking_stages,
        bedrooms: params[:bedrooms].to_i,
        carpet: "#{params[:carpet].to_f - 50}-#{params[:carpet].to_f + 50}"
      }
    }).count
    respond_to do |format|
      format.json {render json: {message: "#{data + 6} other such #{params[:bedrooms]} BHK apartments sold"}}
    end
  end

  #
  # This download_brochure action for Admin users where brochure download will start.
  #
  # GET /dashboard/download_brochure
  #
  def download_brochure
    send_file(open(current_client.brochure.url),
          :filename => "Brochure.#{current_client.brochure.file.extension}",
          :type => current_client.brochure.content_type,
          :disposition => 'attachment',
          :url_based_filename => true)
    current_user.portal_stage << PortalStage.new(stage: 'project_info') if current_user.buyer? && current_user.receipts.count == 0
  end
end
