module ProjectUnitsConcern
  extend ActiveSupport::Concern

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
    @scheme = Scheme.where(_id: params[:selected_scheme_id]).first
    @project_unit.scheme=(@scheme) if @scheme

    respond_to do |format|
      format.json { render json: @project_unit }
      format.html do
        render layout: params[:layout].blank?, template: 'admin/project_units/show'
      end
    end
  end

  private

  def set_project_unit
    @project_unit = ProjectUnit.find(params[:id])
  end
end
