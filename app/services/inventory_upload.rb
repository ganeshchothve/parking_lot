module BulkUpload
  class Inventory
    def self.upload(filepath, booking_portal_client_id, bulk_upload_report_id)
      bulk_upload_report = BulkUploadReport.find bulk_upload_report_id
      csv_file = CSV.read(filepath)
      bulk_upload_report.update(total_rows: (csv_file.count - 1), success_count: 0, failure_count: 0)
      booking_portal_client = Client.find booking_portal_client_id
      client_id = booking_portal_client.selldo_client_id

      developer = Developer.where(name: booking_portal_client.name, booking_portal_client_id: booking_portal_client.id).first
      if developer.blank?
        developer = Developer.create(name: booking_portal_client.name,booking_portal_client_id: booking_portal_client.id)
      end
      count = 0
      costs = {}
      data = {}
      parameters = {}
      csv_file.each do |row|
        if count == 0
          row.each_with_index do |value, index|
            if value.match(/^parameters\|/i)
              parameters[index] = value.split("|").last.strip
            elsif value.match(/^cost\|/i)
              costs[index] = value.split("|")[1..2].map(&:strip)
            elsif value.match(/^data\|/i)
              data[index] = value.split("|").last.strip
            end
          end
        else
          rera_registration_no = row[0].strip rescue ""
          project_name = row[1].strip rescue ""
          project_tower_name = row[2].strip rescue ""
          unit_configuration_name = row[3].strip rescue ""
          unit_name = row[4].strip rescue ""
          floor = row[5].strip rescue ""
          floor_order = row[6].to_s.strip rescue ""
          carpet = row[7].strip.to_f.round(2) rescue ""
          saleable = row[8].strip.to_f.round(2) rescue ""
          base_rate = row[9].strip rescue ""
          floor_rise = row[10].strip rescue ""
          status = row[11].strip rescue ""
          bedrooms = row[12].strip rescue ""
          bathrooms = row[13].strip rescue ""
          unit_facing_direction = row[14].strip rescue ""
          erp_id = row[15].strip rescue ""
          floor_plan_urls = row[16].strip rescue ""
          agreement_price = row[17].strip rescue ""
          all_inclusive_price = row[18].strip rescue ""

          project = Project.where(name: project_name).first
          unless project.present?
            project = Project.create!(rera_registration_no: rera_registration_no, name: project_name, client_id: client_id, booking_portal_client_id: booking_portal_client.id)
          end

          project_tower = ProjectTower.where(name: project_tower_name).where(project_id: project.id).first
          unless project_tower.present?
            project_tower = ProjectTower.create!(name: project_tower_name, project_id: project.id, client_id: client_id, total_floors: 1)
          end

          unit_configuration = UnitConfiguration.where(name: unit_configuration_name).where(project_id: project.id).where(project_tower_id: project_tower.id).first
          unless unit_configuration.present?
            unit_configuration = UnitConfiguration.create!(name: unit_configuration_name, project_id: project.id, project_tower_id: project_tower.id, client_id: client_id, saleable: saleable.to_f, carpet: carpet.to_f, base_rate: base_rate.to_f)
          end
          if(ProjectUnit.where(erp_id: erp_id).blank?)
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
            elsif status == "Not Available"
              project_unit.status = "not_available"
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
            project_unit.agreement_price = agreement_price.to_i
            project_unit.all_inclusive_price = all_inclusive_price.to_i
            project_unit.base_rate = base_rate.to_f
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

            costs.each do |index, arr|
              project_unit.costs.build(category: arr[0], name: arr[1], absolute_value: row[index], key: arr[1].gsub(/[\W_]+/i, "_").downcase)
            end
            data.each do |index, name|
              project_unit.data.build(name: name, absolute_value: row[index], key: name.downcase.gsub(/[\W_]+/i, "_").downcase)
            end
            parameters.each do |index, name|
              project_unit.parameters.build(name: name, value: row[index], key: name.downcase.gsub(/[\W_]+/i, "_").downcase)
            end
            if project_unit.save
              if floor_plan_urls.present?
                floor_plan_urls.split(",").each do |url|
                  Asset.create(remote_file_url: url, assetable: project_unit, asset_type: "floor_plan")
                end
              end
              bulk_upload_report.success_count = bulk_upload_report.success_count + 1 
              # puts "Saved #{project_unit.name}"
            else
              bulk_upload_report.failure_count = bulk_upload_report.failure_count + 1
              bulk_upload_report.upload_errors << UploadError.new(row: row, messages: project_unit.errors.full_messages)
              # puts "Error in saving #{project_unit.name} : #{project_unit.errors.full_messages}"
            end
            bulk_upload_report.save
          end
        end
        count += 1
      end

      results = ProjectUnit.collection.aggregate([{"$group" => {"_id" => "$project_tower_id", max: {"$max" => "$floor"}}}]).to_a
      results.each do |result|
        tower = ProjectTower.find result["_id"]
        tower.total_floors = result["max"]
        tower.save
      end
    end
  end
end