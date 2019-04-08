module SearchConcern
  extend ActiveSupport::Concern

  def search_for_project_unit
    @tower = ProjectTower.find(id: @search.project_tower_id)
    parameters = @search.params_json
    parameters[:status] = ProjectUnit.user_based_available_statuses(@search.user)
    parameters[:project_tower_id] = @search.project_tower_id if @search.project_tower_id.present?
    @units = ProjectUnit.build_criteria({fltrs: parameters}).sort_by{|x| [x.floor, x.floor_order]}.to_a
    @all_units = ProjectUnit.collection.aggregate([{
      "$match": {
        project_tower_id: BSON::ObjectId(@search.project_tower_id)
      }
    },{
      "$group": {
        "_id": {
          floor: "$floor"
        },
        floor_order: {
          "$addToSet": "$floor_order"
        }
      }
    }, {"$unwind": "$floor_order"
    }, {
      "$sort": {
        "_id.floor": -1,
        "floor_order": 1
      }
    }, {
      "$group": {
        "_id": "$_id.floor",
        "floor_order": {
          "$push": "$floor_order"
        }
      }
    }, {
      "$sort": {
        "_id": -1
      }
    }]).to_a
    @all_units = @all_units.collect{|x| x.with_indifferent_access}
  end

  def search_for_towers
    parameters = @search.params_json
    project_tower_ids = ProjectUnit.build_criteria({fltrs: parameters}).in(status: ProjectUnit.user_based_available_statuses(current_user)).distinct(:project_tower_id)
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
