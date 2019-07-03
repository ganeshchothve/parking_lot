class Admin::PortalStagePrioritiesController < AdminController
  before_action :authorize_resource
  #
  # index
  # GET admin/portal_stage_priorities
  #
  def index
    @portal_stage_priorities = PortalStagePriority.asc(:priority)
      respond_to do |format|
        format.json { render json: @portal_stage_priorities }
        format.html {}
      end
  end

  #
  # reorder
  # PATCH admin/portal_stage_priorities
  # updates the order of priority
  #
  def reorder
    stage_order = Array.new
    params[:order].split(',').each do |priority|
      stage_order.push(PortalStagePriority.find_by(priority: priority).stage) if priority.present?
    end
    PortalStagePriority.each_with_index do |psp, i|
      psp.set(stage: stage_order[i])
    end
    respond_to do |format|
      format.html{ redirect_to admin_portal_stage_priorities_path }
    end

  end

  def authorize_resource
      authorize [current_user_role_group, PortalStagePriority]
  end
end

