module SearchConcern
  extend ActiveSupport::Concern

  def search_for_project_unit
    #
    # Commented for now, can be used if buyer wants to initiate booking process from looking at the inventory.
    #
    parameters = @search.params_json
    parameters[:status] = ProjectUnit.user_based_available_statuses(@search.user)
    parameters[:project_tower_id] = @search.project_tower_id if @search.project_tower_id.present?
    @units = ProjectUnit.build_criteria({fltrs: parameters}).sort_by{|x| [x.floor, x.floor_order]}.to_a

    match = { "$match": { project_tower_id: @project_tower_id } } if @project_tower_id
    @all_units = ProjectUnit.collection.aggregate([match, {
      "$group": {
        "_id": {
          floor: "$floor",
          floor_order: "$floor_order"
        }
      }
    }, {
      "$sort": {
        "_id.floor_order": 1
      }
    }, {
      "$group": {
        "_id": "$_id.floor",
        "floor_order": {
          "$push": "$_id.floor_order"
        }
      }
    }, {
      "$sort": {
        "_id": -1
      }
    }].compact).to_a
    @all_units = @all_units.collect{|x| x.with_indifferent_access}
  end

  def search_for_towers
    parameters = @search.params_json
    if @user.manager && @user.manager.role?('channel_partner')
      filters = {fltrs: { can_be_applied_by: @user.manager.role, user_role: @user.role, user_id: @user.id, status: 'approved', default_for_user_id: @user.manager.id } }
      project_tower_ids_for_channel_partner = Scheme.build_criteria(filters).distinct(:project_tower_id)
    end
    project_units = ProjectUnit.build_criteria({fltrs: parameters}).in(status: ProjectUnit.user_based_available_statuses(current_user))
    project_units = project_units.in(project_tower_id: project_tower_ids_for_channel_partner) if project_tower_ids_for_channel_partner.present?
    project_tower_ids = project_units.distinct(:project_tower_id)
    @towers = ProjectTower.in(id: project_tower_ids).collect do |x|
      hash = {project_tower_id: x.id, project_tower_name: x.name, assets: x.assets.as_json}
      # GENERIC_TODO: handle floor plan url here
      hash[:floors] = x.total_floors
      hash[:total_units] = ProjectUnit.where(project_tower_id: x.id).count
      hash[:total_units_available] = ProjectUnit.build_criteria({fltrs: parameters}).where(project_tower_id: x.id).in(status: ProjectUnit.user_based_available_statuses(current_user)).count
      hash
    end
    # GENERIC TODO: If no results found we should display alternate towers
  end
end
