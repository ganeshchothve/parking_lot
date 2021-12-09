class Admin::BookingDetailsController < AdminController
  include BookingDetailConcern
  include SearchConcern
  around_action :apply_policy_scope, only: [:index, :mis_report]
  before_action :set_booking_detail, except: [:index, :mis_report, :new, :create, :searching_for_towers, :status_chart, :new_booking_without_inventory, :create_booking_without_inventory, :edit_booking_without_inventory, :update_booking_without_inventory, :move_to_next_state]
  before_action :authorize_resource, except: [:index, :mis_report, :new, :create, :searching_for_towers, :status_chart, :new_booking_without_inventory, :create_booking_without_inventory, :edit_booking_without_inventory, :update_booking_without_inventory, :move_to_next_state]
  before_action :set_project_unit, only: :booking
  before_action :set_receipt, only: :booking

  def index
    authorize [:admin, BookingDetail]
    respond_to do |format|
      format.json { render json: booking_detail_for_json }
      format.html { booking_details_for_html_request }
    end
  end

  def new
    @search = Search.new()
    @booking_detail = BookingDetail.new(search: @search)
    @project_towers = search_for_towers
    @project_towers.map!{|f| [f[:project_tower_name], f[:project_tower_id]]}
    # authorize [:admin, @booking_detail]
    render layout: false
  end

  def create
    _project_unit = ProjectUnit.find(params[:booking_detail][:project_unit_id])
    _search = Search.create(user_id: params[:booking_detail][:user_id], lead_id: params[:booking_detail][:lead_id], project_tower_id: params[:project_tower_id] || _project_unit.project_tower.id, project_unit_id: params[:booking_detail][:project_unit_id])
    @booking_detail = BookingDetail.new(search: _search)
    @booking_detail.assign_attributes(permitted_attributes([:admin, @booking_detail]))
    @booking_detail.assign_attributes(
      base_rate: _project_unit.base_rate,
      floor_rise: _project_unit.floor_rise,
      saleable: _project_unit.saleable,
      costs: _project_unit.costs,
      data: _project_unit.data
    )
    @booking_detail.create_default_scheme
    authorize [:admin, @booking_detail]
    respond_to do |format|
      if @booking_detail.booking_detail_scheme.present? && @booking_detail.save
        response.set_header('location', checkout_lead_search_path(_search.id, lead_id: _search.lead_id) )
        format.json { render json: {message: "booking_successful"}, status: :ok }
        format.html { redirect_to checkout_lead_search_path(_search.id, lead_id: _search.lead_id) }
      else
        format.html { redirect_to dashboard_path, alert: t('controller.booking_details.booking_unsuccessful') }
      end
    end
  end

  def show
    @scheme = @booking_detail.booking_detail_scheme
  end

  def edit
    render layout: false
  end

  def update
    respond_to do |format|
      if @booking_detail.update(permitted_attributes([:admin, @booking_detail]))
        format.html { redirect_to admin_booking_details_path }
      else
        format.html { render :edit }
        format.json { render json: { errors: @booking_detail.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def booking
    # This will return @receipt object
    # In before_action set booking_detail project_unit, receipt and redirect_to to dashboard_path when any one of this is missing.
    if @receipt.save
      @receipt.change_booking_detail_status
      redirect_to admin_lead_path(@receipt.lead), notice: t('controller.booking_details.booking_successful')
    else
      redirect_to checkout_lead_search_path(@booking_detail.search), alert: @receipt.errors.full_messages
    end
  end

  def tasks
    @booking_detail.map_tasks
    render layout: false
  end

  def send_under_negotiation
    @booking_detail.under_negotiation!
    respond_to do |format|
      format.html { redirect_to admin_lead_path(@booking_detail.lead_id) }
    end
  end

  #
  # This mis_report action for Admin users where Admin will be mailed the report
  #
  # GET /admin/booking_details/mis_report
  #
  def mis_report
    BookingDetailMisReportWorker.perform_async(current_user.id.to_s)
    flash[:notice] = 'Your mis-report has been scheduled and will be emailed to you in some time'
    redirect_to request.referer || dashboard_path
  end

  #
  # This searching_for_towers for Admin users which is used to search for towers in one step booking
  #
  # GET /admin/booking_details/searching_for_towers
  #

  def searching_for_towers
    towers = search_for_towers(params[:lead_id])
    towers.map!{|f| [f[:project_tower_name], f[:project_tower_id]]} if towers.present?
    # GENERIC TODO: If no results found we should display alternate towers
    respond_to do |format|
      if towers.present?
        format.json { render json: towers, status: :ok }
      else
        format.json { render json: {errors: 'Towers not present for this user'}, status: :not_found }
      end
    end
  end

  def doc
    render layout: false
  end
  #
  # GET /admin/booking_details/status_chart
  #
  # This method is used in admin dashboard
  #
  def status_chart
    authorize [:admin, BookingDetail]
    @data = DashboardData::AdminDataProvider.booking_detail_block(params)
    @statuses = params[:status] || %w[under_negotiation blocked booked_tentative booked_confirmed]
    @dataset = get_dataset(@data, @statuses)
  end

  #
  # This method sends booking detail form on email.
  #
  # GET /admin/booking_details/send_booking_detail_form_notification/:id
  #
  def send_booking_detail_form_notification
    @booking_detail.send_booking_detail_form_mail_and_sms
    redirect_to (request.referrer.present? ? request.referrer : admin_booking_details_path), notice: t('controller.booking_details.send_booking_detail_form_notification')
  end

  def new_booking_without_inventory
    @booking_detail = BookingDetail.new(lead_id: params[:lead_id])
    render layout: false
  end

  def create_booking_without_inventory
    @booking_detail = BookingDetail.new
    @booking_detail.assign_attributes(permitted_attributes([:admin, @booking_detail]))
    @booking_detail.manager = current_user
    @booking_detail.user = @booking_detail.lead.user
    @booking_detail.status = "blocked"
    respond_to do |format|
      if @booking_detail.save
        format.json { render json: {message: "booking_successful"}, status: :ok }
        format.html { redirect_to admin_leads_path }
      else
        format.html { redirect_to dashboard_path, alert: t('controller.booking_details.booking_unsuccessful') }
      end
    end
  end

  def edit_booking_without_inventory
    @booking_detail = BookingDetail.find_by(id: params[:id])
    render layout: false
  end

  def update_booking_without_inventory
    @booking_detail = BookingDetail.find_by(id: params[:id])
    @booking_detail.assign_attributes(permitted_attributes([:admin, @booking_detail]))
    respond_to do |format|
      if @booking_detail.save
        format.json { render json: {message: "booking_successful"}, status: :ok }
        format.html { redirect_to admin_leads_path }
      else
        format.html { redirect_to dashboard_path, alert: t('controller.booking_details.booking_unsuccessful') }
      end
    end
  end

  def move_to_next_state
    @booking_detail = BookingDetail.find_by(id: params[:id])
    respond_to do |format|
      if @booking_detail.move_to_next_state!(params[:status])
        format.html{ redirect_to request.referrer || dashboard_url, notice: "Booking moved to #{params[:status]} successfully" }
        format.json { render json: { message: "Booking moved to #{params[:status].humanize} successfully" }, status: :ok }
      else
        format.html{ redirect_to request.referrer || dashboard_url, alert: @booking_detail.errors.full_messages.uniq }
        format.json { render json: { errors: @booking_detail.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_booking_detail
    @booking_detail = BookingDetail.where(_id: params[:id]).first
    redirect_to dashboard_path, alert: t('controller.booking_details.set_booking_detail_missing') if @booking_detail.blank?
  end

  def set_project_unit
    @project_unit = @booking_detail.project_unit
    redirect_to dashboard_path, alert: t('controller.booking_details.set_project_unit_missing') if @project_unit.blank?
  end

  def authorize_resource
    authorize [:admin, @booking_detail]
  end

  def set_receipt
    @receipt = @booking_detail.lead.unattached_blocking_receipt @project_unit.blocking_amount
    if @receipt.present?
      @receipt.booking_detail_id = @booking_detail.id
    else
      redirect_to new_admin_booking_detail_receipt_path(@booking_detail.lead, @booking_detail), notice: t('controller.booking_details.set_receipt_missing')
    end
  end

  def booking_details_for_html_request
    @booking_details = BookingDetail.includes(:project_unit, :user, :booking_detail_schemes).build_criteria(params).paginate(page: params[:page] || 1, per_page: params[:per_page])
  end

  def booking_detail_for_json
    @booking_details = BookingDetail.build_criteria(params).paginate(page: params[:page] || 1, per_page: params[:per_page]).as_json(methods: [:ds_name])
  end

  def get_dataset(out, statuses)
    labels= ProjectTower.distinct(:name)
    dataset = Array.new
    statuses.each do |status|
      d = Array.new
      labels.each do |l|
        if out[l.to_sym].present? && out[l.to_sym][status.to_sym].present?
          d << (out[l.to_sym][status.to_sym])
        else
          d << 0
        end
      end
      dataset << { label: t("mongoid.attributes.booking_detail/status.#{status}"),
                    borderColor: '#ffffff',
                    borderWidth: 1,
                    data: d
                  }
    end
    dataset
  end

end
