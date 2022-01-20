class DashboardController < ApplicationController
  include SourcingManagerDashboardConcern
  include BillingTeamDashboardConcern
  include ChannelPartnerDashboardConcern
  include BookingDetailDashboardConcern
  before_action :authenticate_user!, only: [:index, :documents]
  before_action :set_lead, only: :index, if: proc { current_user.buyer? }
  around_action :user_time_zone, if: :current_user

  layout :set_layout

  def index
    authorize :dashboard, :index?
    @customer_search = CustomerSearch.new if current_user.role == 'gre'
    @project_units = current_user.project_units

    if ['channel_partner', 'cp_owner'].include?(current_user.role)
      @offer_assets = BannerAsset.filter_by_publish
    end

    respond_to do |format|
      format.json { render json: { message: 'Logged In' }, status: 200 }
      if current_user.role?('dev_sourcing_manager')
        format.html { redirect_to :admin_site_visits }
      else
        format.html {}
      end
    end
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
      SelldoLeadUpdater.perform_async(current_user.selected_lead_id.to_s, {stage: 'project_info'}) if current_user.buyer? && current_user.selected_lead&.receipts&.count == 0
    else
      redirect_to dashboard_path, alert: 'Brochure is not available'
    end
  end

  def sales_board
    authorize :dashboard
    @users = User.where(User.user_based_scope(current_user, params)).where(role: 'sales').asc(:sales_status)
  end

  private

  def user_time_zone
    Time.use_zone(current_user.time_zone) { yield }
  end

  def set_lead
    unless @lead = current_user.selected_lead
      redirect_to welcome_path, alert: t('controller.application.set_current_client')
    end
  end
end
