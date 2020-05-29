module ProjectUnitsConcern
  extend ActiveSupport::Concern

  included do
    before_action :build_objects, only: %i[quotation show send_cost_sheet_and_payment_schedule]
    before_action :modify_params, only: %i[quotation show send_cost_sheet_and_payment_schedule]
    before_action :set_user, only: %w[quotation send_cost_sheet_and_payment_schedule]
  end

  #
  # This edit action for Admin, users to edit the details of existing project unit record.
  #
  def edit
    render layout: false
  end

  #
  # This show action for Admin users where Admin can view details of a particular project unit.
  #
  # @return [{}] record with array of Hashes.
  # GET /admin/project_units/:id
  #
  def show
    @booking_details = BookingDetail.where(project_unit_id: @project_unit.id).paginate(page: params[:page] || 1, per_page: 15)
    respond_to do |format|
      format.json { render json: @project_unit }
      format.html do
        render layout: params[:layout].blank?, template: 'admin/project_units/show'
      end
    end
  end

  #
  # This will give cost sheet  in html and pdf format of the project unit and allows to change scheme and add payment adjustments.
  #
  # GET /<admin/buyer>/project_units/:id/quotation
  #
  def quotation
    respond_to do |format|
      format.js
      format.pdf {
        render pdf: "quotation",
        template: 'admin/project_units/quotation',
        layout: 'pdf',
        page_size: 'A4',
        zoom: 1,
        dpi: 75,
        orientation: "Landscape",
        margin: { top: 15, bottom: 15 },
        footer: {
          center: t('controller.project_units.quotation.pdf_footer'),
          font_size: 10,
          spacing: 10
        },
        lowquality: true
      }
      format.html do
        render layout: params[:layout].blank?, template: 'admin/project_units/quotation'
      end
    end
  end

  private

  def set_user
    if params[:user_id]
      @user = User.where(id: params[:user_id]).first
    end
  end

  def set_project_unit
    @project_unit = ProjectUnit.find(params[:id])
  end

  def build_objects
    @booking_detail = BookingDetail.new(name: @project_unit.name, base_rate: @project_unit.base_rate, floor_rise: @project_unit.floor_rise, saleable: @project_unit.saleable, costs: @project_unit.costs, data: @project_unit.data, project_unit: @project_unit )
    @booking_detail_scheme = BookingDetailScheme.new(booking_detail: @booking_detail, project_unit: @project_unit)
  end

  def modify_params
    if params[:booking_detail_scheme]
      @booking_detail_scheme.assign_attributes(permitted_attributes([ current_user_role_group, @booking_detail_scheme]))
      @booking_detail_scheme.payment_adjustments <<  @booking_detail_scheme.derived_from_scheme.payment_adjustments.clone.map{|ad| ad.set(editable: false)}
    else
      @booking_detail_scheme.payment_adjustments << @project_unit.scheme.payment_adjustments.clone.map{|ad| ad.set(editable: false)}
      @booking_detail_scheme.derived_from_scheme = @project_unit.scheme
    end
    @booking_detail_scheme.set(cost_sheet_template: @booking_detail_scheme.derived_from_scheme.cost_sheet_template, payment_schedule_template: @booking_detail_scheme.derived_from_scheme.payment_schedule_template)
    @booking_detail.booking_detail_scheme = @booking_detail_scheme
  end
end
