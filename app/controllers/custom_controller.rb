class CustomController < ApplicationController
  include CustomConcern
  include SearchConcern
  before_action :authenticate_user!
  layout :set_layout

  def inventory
    @project_towers = ProjectTower.all
    @project_tower = params[:project_tower_id].present? ? ProjectTower.find(params[:project_tower_id]) : ProjectTower.asc(:name).first
    @search = Search.new(project_tower_id: @project_tower.id, user: current_user)
    search_for_project_unit
  end

end
