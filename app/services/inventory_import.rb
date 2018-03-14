class InventoryImport
  include Api::SellDoController

  def run file_path, has_header=true
    input_file = CSV.open(file_path, "r")
    selldo_client_id = Api::SellDoController.new.send(:client_id)
    project = Project.first
    tower_names = {}
    input_file.each_with_index do |row, index|
      if has_header && index.zero?
        next
      end
      if row[2].present?
        tower_names[row[2]] = row[5].to_i if tower_names.keys.exclude?(row[2]) || tower_names[row[2]] < row[5].to_i
      end
    end
    tower_names.each do |tower_name, floors|
      project_tower = ProjectTower.where(name: tower_name).first
      if project_tower.blank?
        project_tower = ProjectTower.new(name: tower_name)
        project_tower.project = project
        project_tower.client_id = selldo_client_id
        project_tower.total_floors = floors
        project_tower.save!
      end
    end
    input_file = CSV.open(file_path, "r")
    input_file.each_with_index do |row, index|
      if has_header && index.zero?
        next
      end
      sfdc_id = row[0]
      status = row[20]
      if sfdc_id.present?
        unit = ProjectUnit.where(sfdc_id: sfdc_id).first
        if unit.blank?
          unit = ProjectUnit.new(sfdc_id: sfdc_id)
        end
        unit.name = row[3]
        data_attributes = [{
          n: "project_name", v: row[1]
        },{
          n: "project_tower_name", v: row[2]
        },{
          n: "developer_name", v: "Embassy Group"
        },{
          n: "floor", v: row[5].to_i
        },{
          n: "bedrooms", v: row[6].to_f
        },{
          n: "bathrooms", v: row[7].to_f
        },{
          n: "carpet", v: row[8].to_f
        },{
          n: "saleable", v: row[9].to_f
        },{
          n: "category", v: row[10]
        },{
          n: "unit_configuration_name", v: row[11]
        },{
          n: "type", v: row[12]
        }, {
          n: "base_rate", v: 4299
        }]
        costs = [{
          name: "City infrastructure charges", value: row[13].to_f, calculation_type: "absolute"
        },{
          name: "Water/Electricity/Power Backup", value: row[14].to_f, calculation_type: "absolute"
        },{
          name: "Advance Maintenance charges for 1 year", value: row[15].to_f, calculation_type: "absolute"
        },{
          name: "Club house & amenities Charges", value: row[16].to_f, calculation_type: "absolute"
        },{
          name: "Corpus Fund", value: row[17].to_f, calculation_type: "absolute"
        },{
          name: "Premium Charges", value: row[18].to_f, calculation_type: "absolute"
        }]
        unit.costs = costs
        unit.data_attributes = data_attributes
        unit.status = status.downcase == "available" ? "available" : "not_available"
        unit.project = project
        unit.project_tower_id = ProjectTower.where(name: row[2]).first.id
        unit.client_id = selldo_client_id
        unit.base_price = unit.costs.collect{|x| x[:value]}.sum + (4299 * row[8].to_f)
        unit.valid?
        unit.save!
      end
      # unit_number = row[4]
      # floor_rise = row[19]
    end
  end
end

