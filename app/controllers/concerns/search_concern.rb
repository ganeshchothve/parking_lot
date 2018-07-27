module SearchConcern
  extend ActiveSupport::Concern

  def search_for_project_unit
    @tower = ProjectTower.find(id: @search.project_tower_id)
    parameters = @search.params_json
    parameters[:status] = ProjectUnit.user_based_available_statuses(@search.user)
    @units = ProjectUnit.build_criteria({fltrs: parameters}).sort{|x, y| y.floor <=> x.floor}.to_a
  end

  def search_for_towers
    parameters = @search.params_json
    project_tower_ids = ProjectUnit.build_criteria({fltrs: parameters}).in(status: ProjectUnit.user_based_available_statuses(current_user)).distinct(:project_tower_id)
    @towers = ProjectTower.in(id: project_tower_ids).collect do |x|
      hash = {project_tower_id: x.id, project_tower_name: x.name}
      # GENERIC_TODO: handle floor plan url here
      hash[:total_units] = ProjectUnit.where(project_tower_id: x.id).count
      hash[:total_units_available] = ProjectUnit.build_criteria({fltrs: parameters}).where(project_tower_id: x.id).in(status: ProjectUnit.user_based_available_statuses(current_user)).count
      hash
    end
    if @towers.blank?
      alternative_params = {}
      @alternative_count = 0
      if bedroom != "NA"
        alternative_params =  {fltrs: {bedrooms: bedroom != "NA" ? bedroom : ""}}
      elsif agreement_price != "NA"
        alternative_params =  {fltrs: {agreement_price: budget != "NA" ? budget : ""}}
      end
      @alternative_count = ProjectUnit.build_criteria({fltrs: parameters}).in(status: ProjectUnit.user_based_available_statuses(current_user)).count if alternative_params.present?
    end
  end
end
