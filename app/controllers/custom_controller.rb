class CustomController < ApplicationController
  include CustomConcern
  include SearchConcern
  before_action :authenticate_user!
  before_action :set_project
  layout :set_layout

  def inventory
    @project_towers = @project.project_towers.all
    @project_towers = @project_towers.where(_id: params[:project_tower_id], booking_portal_client_id: current_client.try(:id)) if !params[:project_tower_id].blank?
    authorize :custom, :inventory?

    # Commented for now, can be used if buyer wants to initiate booking process from looking at the inventory.
    # @search = Search.new(project_tower_id: @project_tower.id, user: current_user)
    # search_for_project_unit
  end

  private

  def set_project
    @project = Project.where(id: params[:id], booking_portal_client_id: current_client.try(:id)).first
    redirect_to root_path, alert: I18n.t("controller.projects.alert.not_found") unless @project
  end
end
