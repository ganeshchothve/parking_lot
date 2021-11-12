class Admin::Projects::TimeSlotsController < AdminController
  before_action :set_project
  before_action :set_time_slot, except: [:index, :new, :create]
  before_action :authorize_resource
  around_action :user_time_zone, if: :current_user

  # GET /admin/projects/:project_id/time_slots
  #
  def index
    @time_slots = @project.time_slots.all.paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.json { render json: @time_slots }
      format.html {}
    end
  end

  # GET /admin/projects/:project_id/time_slots
  #
  def new
    @time_slot = @project.time_slots.build
    render layout: false
  end

  # POST /admin/projects/:project_id/time_slots/:id
  #
  def create
    @time_slot = @project.time_slots.build
    @time_slot.assign_attributes(permitted_attributes([current_user_role_group, @time_slot]))

    respond_to do |format|
      if @time_slot.save
        format.html { redirect_to admin_project_time_slots_path, notice: 'Time slot was successfully created.' }
        format.json { render json: @time_slot, status: :created }
      else
        errors = @time_slot.errors.full_messages
        errors.uniq!
        format.html { render :new }
        format.json { render json: { errors: errors }, status: :unprocessable_entity }
      end
    end
  end

  # GET /admin/projects/:project_id/time_slots/:id
  #
  def edit
    render layout: false
  end

  # PATCH /admin/projects/:project_id/time_slots/:id
  #
  def update
    parameters = permitted_attributes([:admin, @time_slot])
    respond_to do |format|
      if @time_slot.update(parameters)
        format.html { redirect_to request.referrer || admin_project_time_slots_path, notice: 'Time slot successfully updated.' }
      else
        errors = @time_slot.errors.full_messages
        errors.uniq!
        format.html { render :edit }
        format.json { render json: { errors: errors }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @time_slot.destroy
        format.html { redirect_to request.referrer || admin_project_time_slots_path, notice: 'Time slot successfully deleted.' }
        format.json {render json: {}, status: :ok}
      else
        format.json {render json: {errors: @time_slot.errors.full_messages.to_sentence}, status: :unprocessable_entity}
      end
    end
  end

  private

  def set_project
    @project = Project.where(id: params[:project_id]).first
    redirect_to dashboard_path, alert: 'Project not found' unless @project
  end

  def set_time_slot
    @time_slot = @project.time_slots.where(id: params[:id]).first
    redirect_to dashboard_path, alert: 'Time slot not found' unless @time_slot
  end

  def user_time_zone
    Time.use_zone(current_user.time_zone) { yield }
  end

  def authorize_resource
    if %w[index].include?(params[:action])
      authorize [:admin, TimeSlot]
    elsif params[:action] == 'new'
      authorize [:admin, TimeSlot.new]
    elsif params[:action] == 'create'
      authorize [:admin, TimeSlot.new(permitted_attributes([:admin, TimeSlot.new]))]
    else
      authorize [:admin, @time_slot]
    end
  end
end