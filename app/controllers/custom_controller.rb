class CustomController < ApplicationController
  include CustomConcern
  include SearchConcern
  before_action :authenticate_user!
  layout :set_layout

  def inventory
    @project_towers = ProjectTower.all
    @project_tower_id = BSON::ObjectId(params[:project_tower_id]) rescue nil
    @project_towers = @project_towers.where(id: @project_tower_id) if @project_tower_id
    # Commented for now, can be used if buyer wants to initiate booking process from looking at the inventory.
    #@project_tower = @project_towers.first
    #@search = Search.new(project_tower_id: @project_tower.id, user: current_user)
    search_for_project_unit
  end

end
