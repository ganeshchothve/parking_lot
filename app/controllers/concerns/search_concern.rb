module SearchConcern
  extend ActiveSupport::Concern

  def search_for_project_unit
    #
    # Commented for now, can be used if buyer wants to initiate booking process from looking at the inventory.
    #
    match = {}
    parameters = @search.params_json
    parameters[:status] = ProjectUnit.user_based_available_statuses(@lead.user)
    if @search.project_id.present?
      parameters[:project_id] = @search.project_id
      match = { "$match": { project_id: @search.project_id } }
    end
    if @search.project_tower_id.present?
      parameters[:project_tower_id] = @search.project_tower_id
      match["$match"] ||= {}
      match["$match"][:project_tower_id] = @search.project_tower_id
    end
    @units = ProjectUnit.build_criteria({fltrs: parameters}).sort_by{|x| [x.floor, x.floor_order]}.to_a

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

  def search_for_towers(lead_id = nil)
    @lead ||= Lead.where(booking_portal_client_id: current_client.try(:id), id: lead_id).first
    parameters = {}
    parameters = @search.params_json if @search.present?
    project_units = ProjectUnit.build_criteria({fltrs: parameters}).in(status: ProjectUnit.user_based_available_statuses(@lead.user))
    if @lead.present? && @lead.manager_role?('channel_partner')
      filters = {fltrs: { can_be_applied_by_role: @lead.manager_role, user_role: @lead.user_role, user_id: @lead.user_id, status: 'approved', default_for_user_id: @lead.manager_id } }
      project_tower_ids_for_channel_partner = Scheme.build_criteria(filters).distinct(:project_tower_id)
      project_units = project_units.in(project_tower_id: project_tower_ids_for_channel_partner)
    end
    project_tower_ids = project_units.distinct(:project_tower_id)
    @towers = ProjectTower.in(id: project_tower_ids).collect do |x|
      hash = {project_tower_id: x.id, project_tower_name: x.name, assets: x.assets.as_json}
      # GENERIC_TODO: handle floor plan url here
      hash[:floors] = x.total_floors
      hash[:total_units] = ProjectUnit.where(booking_portal_client_id: current_client.try(:id), project_tower_id: x.id).count
      hash[:total_units_available] = ProjectUnit.build_criteria({fltrs: parameters}).where(booking_portal_client_id: current_client.try(:id), project_tower_id: x.id).in(status: ProjectUnit.user_based_available_statuses(@lead.user)).count
      hash
    end
    # GENERIC TODO: If no results found we should display alternate towers
  end
end
