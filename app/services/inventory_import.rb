module InventoryImport
  def self.update(filepath, booking_portal_client_id)
    booking_portal_client = Client.find booking_portal_client_id
    count = 0
    CSV.foreach(filepath) do |row|
      unless count == 0
        rera_registration_no = row[0].strip
        project_name = row[1].strip
        project_tower_name = row[2].strip
        unit_name = row[3].strip
        unit_configuration_name = row[4].strip
        floor = row[5].strip
        floor_order = row[6].strip
        carpet = row[7].strip.to_f.round(2)
        saleable = row[8].strip.to_f.round(2)
        base_rate = row[9].strip
        floor_rise = row[10].strip
        status = row[11].strip
        bedrooms = row[12].strip
        bathrooms = row[13].strip
        unit_facing_direction = row[14].strip
        erp_id = row[15].strip

        client_id = booking_portal_client.selldo_client_id

        project_unit = ProjectUnit.in(status: ["not_available", "available", "employee", "management"]).where(erp_id: erp_id).first
        if project_unit.present?
          project_unit.erp_id = erp_id
          project_unit.name = "#{unit_name} | #{unit_configuration_name}"
          if status == "Available"
            project_unit.status = "available"
            project_unit.available_for = "user"
          elsif status == "Management Blocking"
            project_unit.status = "management"
            project_unit.available_for = "management"
          elsif status == "Employee Blocking"
            project_unit.status = "employee"
            project_unit.available_for = "employee"
          else
            project_unit.status = "error"
            project_unit.available_for = "user"
          end
          project_unit.base_rate = base_rate.to_f
          project_unit.floor_rise = floor_rise.to_f

          if project_unit.save
            puts "Saved #{project_unit.name}"
          else
            puts "Error in saving #{project_unit.name} : #{project_unit.errors.full_messages}"
          end
        else
          puts "Not updating project unit: #{unit_name} - #{erp_id}"
        end
      end
      count += 1
    end
  end

  def self.perform(filepath, booking_portal_client_id)
    booking_portal_client = Client.find booking_portal_client_id
    client_id = booking_portal_client.selldo_client_id

    developer = Developer.create(name: booking_portal_client.name, client_id: client_id, booking_portal_client_id: booking_portal_client.id)
    count = 0
    CSV.foreach(filepath) do |row|
      unless count == 0
        rera_registration_no = row[0].strip
        project_name = row[1].strip
        project_tower_name = row[2].strip
        unit_name = row[3].strip
        unit_configuration_name = row[4].strip
        floor = row[5].strip
        floor_order = row[6].strip
        carpet = row[7].strip.to_f.round(2)
        saleable = row[8].strip.to_f.round(2)
        base_rate = row[9].strip
        floor_rise = row[10].strip
        status = row[11].strip
        bedrooms = row[12].strip
        bathrooms = row[13].strip
        unit_facing_direction = row[14].strip
        erp_id = row[15].strip

        project = Project.where(name: project_name).first
        unless project.present?
          project = Project.create!(rera_registration_no: rera_registration_no, name: project_name, client_id: client_id, booking_portal_client_id: booking_portal_client.id)
        end

        project_tower = ProjectTower.where(name: project_tower_name).where(project_id: project.id).first
        unless project_tower.present?
          project_tower = ProjectTower.create!(name: project_tower_name, project_id: project.id, client_id: client_id, total_floors: 14)
        end

        unit_configuration = UnitConfiguration.where(name: unit_configuration_name).where(project_id: project.id).where(project_tower_id: project_tower.id).first
        unless unit_configuration.present?
          unit_configuration = UnitConfiguration.create!(name: unit_configuration_name, project_id: project.id, project_tower_id: project_tower.id, client_id: client_id, saleable: saleable.to_f, carpet: carpet.to_f, base_rate: base_rate.to_f)
        end

        project_unit = ProjectUnit.new
        project_unit.erp_id = erp_id
        project_unit.developer = developer
        project_unit.project = project
        project_unit.project_tower = project_tower
        project_unit.unit_configuration = unit_configuration
        project_unit.booking_portal_client = booking_portal_client

        project_unit.developer_name = developer.name
        project_unit.project_name = project_name
        project_unit.project_tower_name = project_tower_name
        project_unit.unit_configuration_name = unit_configuration_name

        project_unit.name = unit_name
        if status == "Available"
          project_unit.status = "available"
          project_unit.available_for = "user"
        elsif status == "Management Blocking"
          project_unit.status = "management"
          project_unit.available_for = "management"
        elsif status == "Employee Blocking"
          project_unit.status = "employee"
          project_unit.available_for = "employee"
        else
          project_unit.status = "error"
          project_unit.available_for = "user"
        end

        project_unit.base_rate = base_rate.to_f
        project_unit.client_id = client_id
        project_unit.bedrooms = bedrooms.to_f
        project_unit.bathrooms = bathrooms.to_f
        project_unit.carpet = carpet.to_f
        project_unit.saleable = saleable.to_f
        project_unit.floor = floor
        project_unit.floor_order = floor_order
        project_unit.unit_facing_direction = unit_facing_direction
        project_unit.type = "apartment"
        project_unit.selldo_id = erp_id
        project_unit.floor_rise = floor_rise.to_f

        if project_unit.save
          puts "Saved #{project_unit.name}"
        else
          puts "Error in saving #{project_unit.name} : #{project_unit.errors.full_messages}"
        end
      end
      count += 1
    end
  end
end
