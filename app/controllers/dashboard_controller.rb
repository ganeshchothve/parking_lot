class DashboardController < ApplicationController
  before_action :authenticate_user!, only: [:index, :documents]
  layout :set_layout

  def index
    authorize :dashboard, :index?
    @project_units = current_user.project_units
    @receipts = current_user.receipts.paginate(page: params[:page] || 1, per_page: params[:per_page])
    @lead_details_labels = get_lead_detail_labels
    @booking_detail_labels = get_booking_detail_labels

  end

  def faqs
  end

  def documents
    @assetable = current_client
    @assets = current_client.assets.paginate(page: params[:page], per_page: params[:per_page])
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
    if current_client.brochure.present?
      send_file(open(current_client.brochure.url),
            :filename => "Brochure.#{current_client.brochure.file.extension}",
            :type => current_client.brochure.content_type,
            :disposition => 'attachment',
            :url_based_filename => true)
      SelldoLeadUpdater.perform_async(current_user.id.to_s, 'project_info') if current_user.buyer? && current_user.receipts.count == 0
    else
      redirect_to dashboard_path, alert: 'Brochure is not available'
    end
  end

  private

  def get_lead_detail_labels
    labels = Array.new
    DashboardDataProvider.user_group_by(current_user).each do |key, value|
      labels << value.to_s + ' ' + t("dashboard.channel_partner.#{key}")
    end
    labels
  end

  def get_booking_detail_labels
    labels = Array.new
    DashboardDataProvider.booking_detail_group_by(current_user).keys.each do |key|
      labels << t("dashboard.channel_partner.booking_detail.#{key}")
    end
    labels
  end
end
