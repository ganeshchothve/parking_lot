module BulkUpload
  class InventoryUpload < Base

    def initialize(bulk_upload_report)
      super(bulk_upload_report)
      @correct_headers = %w[rera_registration_no project_name project_tower_name unit_configuration_name unit_name floor floor_order carpet saleable base_rate floor_rise status bedrooms bathrooms unit_facing_direction erp_id floor_plan_urls agreement_price all_inclusive_price]
    end

    def process_csv(csv)
      booking_portal_client = bur.client
      client_id = booking_portal_client.selldo_client_id

      developer = Developer.where(name: booking_portal_client.name, booking_portal_client_id: booking_portal_client.id).first
      if developer.blank?
        developer = Developer.create(name: booking_portal_client.name,booking_portal_client_id: booking_portal_client.id)
      end

      costs = {}
      data = {}
      parameters = {}
      csv.headers.each_with_index do |value, index|
        if value.match(/^parameters\|/i)
          parameters[index] = value.split("|").last.strip
        elsif value.match(/^cost\|/i)
          costs[index] = value.split("|")[1..2].map(&:strip)
        elsif value.match(/^data\|/i)
          data[index] = value.split("|").last.strip
        end
      end

      csv.each do |row|
        begin
          rera_registration_no = row.field(0).strip rescue ""
          project_name = row.field(1).strip rescue ""
          project_tower_name = row.field(2).strip rescue ""
          unit_configuration_name = row.field(3).strip rescue ""
          unit_name = row.field(4).strip rescue ""
          floor = row.field(5).strip rescue ""
          floor_order = row.field(6).to_s.strip rescue ""
          carpet = row.field(7).strip.to_f.round(2) rescue ""
          saleable = row.field(8).strip.to_f.round(2) rescue ""
          base_rate = row.field(9).strip rescue ""
          floor_rise = row.field(10).strip rescue ""
          status = row.field(11).strip rescue ""
          bedrooms = row.field(12).strip rescue ""
          bathrooms = row.field(13).strip rescue ""
          unit_facing_direction = row.field(14).strip rescue ""
          erp_id = row.field(15).strip rescue ""
          floor_plan_urls = row.field(16).strip rescue ""
          agreement_price = row.field(17).strip rescue ""
          all_inclusive_price = row.field(18).strip rescue ""

          project = Project.where(name: project_name).first
          unless project.present?
            project = Project.new(rera_registration_no: rera_registration_no, name: project_name, client_id: client_id, booking_portal_client_id: booking_portal_client.id)
            unless project.save
              (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push(*project.errors.full_messages.map{|er| "Project: " + er })).uniq
              bur.failure_count += 1 if bur.upload_errors.where(row: row.fields).present?
              next
            end
          end

          project_tower = ProjectTower.where(name: project_tower_name).where(project_id: project.id).first
          unless project_tower.present?
            project_tower = ProjectTower.new(name: project_tower_name, project_id: project.id, client_id: client_id, total_floors: 1)
            unless project_tower.save
              (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push(*project_tower.errors.full_messages.map{|er| "ProjectTower: " + er })).uniq
              bur.failure_count += 1 if bur.upload_errors.where(row: row.fields).present?
              next
            end
          end

          unit_configuration = UnitConfiguration.where(name: unit_configuration_name).where(project_id: project.id).where(project_tower_id: project_tower.id).first
          unless unit_configuration.present?
            unit_configuration = UnitConfiguration.new(name: unit_configuration_name, project_id: project.id, project_tower_id: project_tower.id, client_id: client_id, saleable: saleable.to_f, carpet: carpet.to_f, base_rate: base_rate.to_f)
            unless unit_configuration.save
              (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push(*unit_configuration.errors.full_messages.map{ |er| "Unit Configuration: " + er })).uniq
              bur.failure_count += 1 if bur.upload_errors.where(row: row.fields).present?
              next
            end
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
            project_unit.blocking_amount = booking_portal_client.blocking_amount if booking_portal_client.blocking_amount.present? && !booking_portal_client.blocking_amount.zero?

            costs.each do |index, arr|
              project_unit.costs.build(category: arr[0], name: arr[1], absolute_value: row[index], key: arr[1].gsub(/[\W_]+/i, "_").downcase)
            end
            data.each do |index, name|
              project_unit.data.build(name: name, absolute_value: row[index], key: name.gsub(/[\W_]+/i, "_").downcase)
            end
            parameters.each do |index, name|
              project_unit.parameters.build(name: name, value: row[index], key: name.gsub(/[\W_]+/i, "_").downcase)
            end
            if project_unit.save
              if floor_plan_urls.present?
                floor_plan_urls.split(",").each do |url|
                  Asset.create(remote_file_url: url, assetable: project_unit, asset_type: "floor_plan")
                end
              end
              bur.success_count = bur.success_count + 1
              # TODO: We will enable it when we get it working.
              # ActionCable.server.broadcast "web_notifications_channel", message: "<p class = 'text-success'>"+ project_unit.name.titleize + " successfully uploaded</p>"
            else
              (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push(*project_unit.errors.full_messages.map{|er| "Project Unit: " + er })).uniq
              bur.failure_count += 1 if bur.upload_errors.where(row: row.fields).present?
              # ActionCable.server.broadcast "web_notifications_channel", message: "<p class = 'text-danger'>"+ project_unit.name.titleize + " - "+ project_unit.errors.full_messages.to_sentence + "</p>"
            end
          else
            (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push("Project Unit with ERP id: #{erp_id} is already present.")).uniq
            bur.failure_count += 1 if bur.upload_errors.where(row: row.fields).present?
          end
        rescue => e
          bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push(["Exception: #{e.message}"] + e.backtrace)
          bur.failure_count += 1 if bur.upload_errors.where(row: row.fields).present?
        end
        # progress = (((count - 1).to_f/bur.total_rows.to_f)*100).ceil
        # ActionCable.server.broadcast "progress_bar_channel", progress: progress.to_s, success: bur.success_count, total: bur.total_rows
      end

      results = ProjectUnit.collection.aggregate([{"$group" => {"_id" => "$project_tower_id", max: {"$max" => "$floor"}}}]).to_a
      results.each do |result|
        tower = ProjectTower.where(id: result["_id"]).first
        if tower
          tower.total_floors = result["max"]
          tower.save
        end
      end
    end

    def validate_headers(headers)
      if headers
        unless headers.compact.map(&:strip).slice(0, 19) == correct_headers
          (bur.upload_errors.find_or_initialize_by(row: headers).messages << 'Invalid headers').uniq
          false
        else
          true
        end
      else
        (bur.upload_errors.find_or_initialize_by(row: headers).messages << 'Headers not found').uniq
        false
      end
    end
  end
end
