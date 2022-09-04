class Admin::PhasesController < AdminController

  before_action :set_phase, except: %i[index new create]

  # index
  # GET /admin/phases
  def index
    @phases = Phase.all
    @phases = @phases.paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.json { render json: @phases }
      format.html {}
    end
  end

  # new
  # GET /admin/phases/new
  def new
    @phase = Phase.new
    render layout: false
  end

  # show
  # GET /admin/phases/:id
  def show
    respond_to do |format|
      format.json { render json: @phase }
      format.html {}
    end
  end

  # edit
  # GET /admin/phases/:id/edit
  def edit
    render layout: false
  end
  #
  # This is the create action for Admin, called after new to create a new phases.
  #
  # POST /admin/phases
  #
  def create
    @phase = Phase.new
    @phase.assign_attributes(permitted_attributes([:admin, @phase]))
    respond_to do |format|
      if @phase.save
        format.html { redirect_to admin_phases_path, notice: I18n.t("controller.accounts.notice.registered") }
        format.json { render json: @phase, status: :created }
      else
        format.html { render :new }
        format.json { render json: { errors: @phase.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  #
  # This is the update action for Phase.
  #
  # PATCH  admin/phase/:id
  #
  def update
    @phase.assign_attributes(permitted_attributes([:admin, @phase]))

    respond_to do |format|
      if @phase.save
        format.html { redirect_to admin_phases_path, notice: I18n.t("controller.accounts.notice.registered") }
        format.json { render json: @phase, status: :created }
      else
        format.html { render :new }
        format.json { render json: { errors: @phase.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_phase
    @phase = Phase.where(id: params[:id]).first
  end
end
