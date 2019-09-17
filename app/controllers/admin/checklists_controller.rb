class Admin::ChecklistsController < AdminController
  before_action :set_checklist, except: %i[index new]
  before_action :authorize_resource

  # index
  # GET /admin/checklists

  def index
    @checklists = current_client.checklists
    @checklists = @checklists.paginate(page: params[:page] || 1, per_page: params[:per_page])
  end

  # new
  # GET /admin/:request_type/accounts/new

  def new
    @checklist = Checklist.new
    render layout: false
  end

  # edit
  # GET /admin/checklists/:id/edit

  def edit
    render layout: false
  end
  
  #
  # This is the destroy action for Checklist.
  #
  #  DELETE admin/checklists/:id
  #
  def destroy
    respond_to do |format|
      if @checklist.destroy
        format.html { redirect_to admin_checklists_path, notice: t('controller.checklists.delete.success') }
      else
        format.html { redirect_to admin_checklists_path, alert: t('controller.checklists.delete.failure') }
      end
    end
  end

  private

  def set_checklist
    @checklist = current_client.checklists.where(id: params[:id]).first
    @checklist.presence || render(json: { location: admin_checklists_path, errors: t('controller.checklists.set_checklist.not_found')}, status: :not_found)
  end

  def authorize_resource
    authorize [current_user_role_group, Checklist]
  end
end
