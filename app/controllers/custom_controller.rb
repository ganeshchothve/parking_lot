class CustomController < ApplicationController
  include CustomConcern
  include SearchConcern
  before_action :authenticate_user!
  layout :set_layout

  def inventory
    @project_towers = ProjectTower.all
    if params[:project_tower_id].present?
      @project_towers = @project_towers.where(id: params[:project_tower_id])
      @project_tower = ProjectTower.find(params[:project_tower_id])
      @search = Search.new(project_tower_id: @project_tower.id, user: current_user)
    end
    search_for_project_unit
  end

end
