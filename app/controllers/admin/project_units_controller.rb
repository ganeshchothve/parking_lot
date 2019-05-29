class Admin::ProjectUnitsController < AdminController
  include ApplicationHelper
  include ProjectUnitsConcern
  before_action :set_project_unit, except: %i[index export]
  before_action :authorize_resource
  before_action :set_project_unit_scheme, only: %i[show print]
  before_action :build_objects, only: %i[quotation]
  around_action :apply_policy_scope, only: :index
  layout :set_layout

  # Defined in ProjectUnitsConcern
  # GET /admin/project_units/:id/edit

  #
  # This index action for Admin users where Admin can view all project units.
  #
  # @return [{},{}] records with array of Hashes.
  # GET /admin/project_units
  #
  def index
    @project_units = ProjectUnit.build_criteria(params).paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      if params[:ds].to_s == 'true'
        format.json { render json: @project_units.collect { |pu| { id: pu.id, name: pu.ds_name } } }
        format.html {}
      else
        format.json { render json: @project_units }
        format.html {}
      end
    end
  end

  #
  # This print action for Admin users where Admin can print a particular project unit(cost sheet and payment schedule).
  #
  # GET /admin/project_units/:id/print
  #
  def print
    @user = @project_unit.user
  end

  #
  # This update action for Admin users is called after edit.
  #
  # PATCH /admin/project_units/:id
  #
  def update
    parameters = permitted_attributes([:admin, @project_unit])
    respond_to do |format|
      if @project_unit.update(parameters)
        format.html { redirect_to admin_project_units_path, notice: 'Unit successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: { errors: @project_unit.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  #
  # This export action for Admin users where Admin will get reports.
  #
  # GET /admin/project_units/export
  #
  def export
    if Rails.env.development?
      ProjectUnitExportWorker.new.perform(current_user.id.to_s, params[:fltrs].as_json)
    else
      ProjectUnitExportWorker.perform_async(current_user.id.to_s, params[:fltrs].as_json)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to admin_project_units_path(fltrs: params[:fltrs].as_json)
  end

  #
  # GET /admin/project_units/:id/send_under_negotiation
  #
  def send_under_negotiation
    @project_unit.booking_detail.under_negotiation!
    respond_to do |format|
      format.html { redirect_to admin_user_path(@project_unit.user.id) }
    end
  end


  # after the booking_detail_scheme is rejected, project_unit can be released by calling this action. It makes the project unit available and marks booking_detail as cancelled.
  def release_unit
    BookingDetail.where(project_unit_id: @project_unit.id).each do |bd|
      bd.cancel!
    end
    @project_unit.status = 'available'
    respond_to do |format|
      if @project_unit.save
        flash[:notice] = t('controller.project_units.unit_released')
        format.html { redirect_to admin_project_unit_path(@project_unit) }
      else
        format.html { redirect_to admin_project_units_path }
      end

    end
  end

  #
  # This will give cost sheet  in html and pdf format of the project unit and allows to change scheme and add payment adjustments.
  #
  # GET /admin/project_units/:id/quotation
  #

  def quotation
    if params[:booking_detail_scheme]
      @booking_detail_scheme.assign_attributes(permitted_attributes([ current_user_role_group, @booking_detail_scheme]))
      @booking_detail_scheme.payment_adjustments <<  @booking_detail_scheme.derived_from_scheme.payment_adjustments.clone.map{|ad| ad.set(editable: false)}
    else
      @booking_detail_scheme.payment_adjustments << @project_unit.scheme.payment_adjustments.clone.map{|ad| ad.set(editable: false)}
      @booking_detail_scheme.derived_from_scheme = @project_unit.scheme
    end
    @booking_detail.booking_detail_scheme = @booking_detail_scheme
    respond_to do |format|
      format.pdf { render pdf: "quotation", layout: 'pdf' }
      format.html
    end
  end

  private

  # def set_project_unit
  # Defined in ProjectUnitsConcern

  def build_objects
    @booking_detail = BookingDetail.new(name: @project_unit.name, base_rate: @project_unit.base_rate, floor_rise: @project_unit.floor_rise, saleable: @project_unit.saleable, costs: @project_unit.costs, data: @project_unit.data, project_unit: @project_unit )
    @booking_detail_scheme = BookingDetailScheme.new(booking_detail: @booking_detail, project_unit: @project_unit)
  end

  def set_project_unit_scheme
    @scheme = Scheme.where(_id: params[:selected_scheme_id]).first
    @project_unit.scheme = @scheme if @scheme
  end

  def authorize_resource
    if params[:action] == 'index'
      if params[:ds].to_s == 'true'
        authorize([:admin, ProjectUnit], :ds?)
      else
        authorize [:admin, ProjectUnit]
      end
    elsif params[:action] == 'export' || params[:action] == 'mis_report'
      authorize [:admin, ProjectUnit]
    else
      authorize [:admin, @project_unit]
    end
  end

  def apply_policy_scope
    custom_project_unit_scope = ProjectUnit.all.criteria
    custom_project_unit_scope = custom_project_unit_scope.or([{ status: 'available' }, { status: { "$in": ProjectUnit.booking_stages }, user_id: { "$in": User.where(referenced_manager_ids: current_user.id).distinct(:id) } }]) if current_user.role == 'channel_partner'

    ProjectUnit.with_scope(policy_scope(custom_project_unit_scope)) do
      custom_scope = User.all.criteria
      custom_scope = custom_scope.in(referenced_manager_ids: current_user.id).in(role: User.buyer_roles(current_client)) if current_user.role == 'channel_partner'
      User.with_scope(policy_scope(custom_scope)) do
        yield
      end
    end
  end
end
