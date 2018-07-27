module InventoryImport
  def self.update(filepath)
    count = 0
    CSV.foreach(filepath) do |row|
      unless count == 0
        sfdc_id = row[0].strip
        project_name = row[1].strip
        project_tower_name = row[2].strip
        unit_name = row[3].strip
        unit_number = row[4].strip
        floor = row[5].strip
        carpet = row[6].strip.to_f.round(2)
        saleable = row[7].strip.to_f.round(2)
        base_rate = row[8].strip
        category = row[9].strip
        unit_configuration_name = row[10].strip
        record_type = row[11].strip

        infrastructure_charges = row[12].strip
        power_supply = row[13].strip
        clubhouse_amenities_price = row[14].strip
        corpus_fund_charges = row[15].strip
        premium_location_charges = row[16].strip
        floor_rise = row[17].strip
        unit_sap_id = row[18]
        status = row[19].strip
        maintenance_deposit = row[20].strip
        bedrooms = row[21].strip
        bathrooms = row[22].strip
        agreement_price = row[23].strip
        land_rate = row[24].strip
        unit_facing_direction = row[25].strip
        usable = row[26].strip
        uds = row[26].strip

        client_id = ENV_CONFIG['selldo']['client_id'] || "531de108a7a03997c3000002"

        project_unit = ProjectUnit.in(status: ["not_available", "available", "employee", "management"]).where(sfdc_id: sfdc_id).first
        if project_unit.present?
          project_unit.sfdc_id = sfdc_id
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
          project_unit.client_id = client_id
          # GENERICTODO: Handle booking_portal_client
          project_unit.selldo_id = unit_sap_id # TODO
          project_unit.agreement_price = agreement_price.to_f
          project_unit.clubhouse_amenities_price = clubhouse_amenities_price
          project_unit.premium_location_charges = premium_location_charges.to_f
          project_unit.floor_rise = floor_rise.to_f
          project_unit.land_rate = land_rate.to_f

          if project_unit.save
            puts "Saved #{project_unit.name}"
          else
            puts "Error in saving #{project_unit.name} : #{project_unit.errors.full_messages}"
          end
        else
          puts "Not updating project unit: #{unit_name} - #{sfdc_id}"
        end
      end
      count += 1
    end
  end

  def self.perform(filepath)
    count = 0
    CSV.foreach(filepath) do |row|
      unless count == 0
        sfdc_id = row[0].strip
        project_name = row[1].strip
        project_tower_name = row[2].strip
        unit_name = row[3].strip
        unit_number = row[4].strip
        floor = row[5].strip
        carpet = row[6].strip.to_f.round(2)
        saleable = row[7].strip.to_f.round(2)
        base_rate = row[8].strip
        category = row[9].strip
        unit_configuration_name = row[10].strip
        record_type = row[11].strip

        infrastructure_charges = row[12].strip
        power_supply = row[13].strip
        clubhouse_amenities_price = row[14].strip
        corpus_fund_charges = row[15].strip
        premium_location_charges = row[16].strip
        floor_rise = row[17].strip
        unit_sap_id = row[18]
        status = row[19].strip
        maintenance_deposit = row[20].strip
        bedrooms = row[21].strip
        bathrooms = row[22].strip
        agreement_price = row[23].strip
        land_rate = row[24].strip
        unit_facing_direction = row[25].strip
        usable = row[26].strip
        uds = row[26].strip

        client_id = ENV_CONFIG['selldo']['client_id'] || "531de108a7a03997c3000002"

        project = Project.where(name: project_name).first
        unless project.present?
          project = Project.create!(name: project_name, client_id: client_id)
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
        project_unit.sfdc_id = sfdc_id
        project_unit.project_id = project.id
        project_unit.project_tower_id = project_tower.id
        project_unit.unit_configuration_id = unit_configuration.id
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
        project_unit.client_id = client_id
        project_unit.bedrooms = bedrooms.to_f
        project_unit.bathrooms = bathrooms.to_f
        project_unit.carpet = carpet.to_f
        project_unit.saleable = saleable.to_f

        project_unit.data_attributes = [{"n"=>"unit_configuration_id", "v"=>"#{unit_configuration.id}"}, {"n"=>"project_name", "v"=>"#{project_name}"}, {"n"=>"project_tower_name", "v"=>"#{project_tower_name}"}, {"n"=>"unit_configuration_name", "v"=>"#{unit_configuration_name}"}, {"n"=>"floor", "v"=> floor}, {"n"=>"resale", "v"=>false}, {"n"=>"category", "v"=>category}, {"n"=>"facing", "v"=>unit_facing_direction}, {"n"=>"type", "v"=>"apartment"}, {"n"=>"usable", "v"=>usable.to_f}, {"n"=>"uds", "v"=>uds.to_f}, {"n"=>"city", "v"=>"Banglore"}, {"n"=>"state", "v"=>"Karnataka"}, {"n"=>"country", "v"=>"India"}, {"n"=>"amenities", "v"=>{}}, {"n"=>"project_status", "v"=>nil}]
        project_unit.selldo_id = unit_sap_id # TODO
        project_unit.sap_id = unit_sap_id # TODO
        project_unit.agreement_price = agreement_price.to_f
        project_unit.clubhouse_amenities_price = clubhouse_amenities_price
        project_unit.premium_location_charges = premium_location_charges.to_f
        project_unit.floor_rise = floor_rise.to_f
        project_unit.land_rate = land_rate.to_f

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
