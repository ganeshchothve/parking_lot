class CustomController < ApplicationController
  include CustomConcern
  include SearchConcern
  before_action :authenticate_user!
  layout :set_layout

  def inventory
    @project_towers = ProjectTower.all
    @project_towers = @project_towers.where(_id: params[:project_tower_id]) if !params[:project_tower_id].blank?
    authorize :custom, :inventory?

    # Commented for now, can be used if buyer wants to initiate booking process from looking at the inventory.
    # @search = Search.new(project_tower_id: @project_tower.id, user: current_user)
    # search_for_project_unit
  end
end
