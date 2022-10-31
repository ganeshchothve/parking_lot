module BulkUpload
  class ProjectUnitsUpdate < Base
    STATUS = {
      'Available' => 'available',
      'Not Available' => 'not_available',
    }

    def initialize(bulk_upload_report)
      super(bulk_upload_report)
      @correct_headers = %w[unit_id rera_registration_no project_name project_tower_name unit_configuration_name unit_name floor floor_order carpet saleable base_rate floor_rise status bedrooms bathrooms unit_facing_direction erp_id blocking_amount]
    end

    def process_csv(csv)
      booking_portal_client = bur.client

      csv.each do |row|
        unit_id = row.field(0).to_s.strip
        project_unit = ::ProjectUnit.where(id: unit_id).first if unit_id.present?
        if project_unit.present?
          begin
            costs = {}
            data = {}
            parameters = {}
            crms = {}
            csv.headers.each_with_index do |value, index|
              if value.match(/^parameters\|/i)
                parameters[index] = value.split("|").last.strip
              elsif value.match(/^cost\|/i)
                costs[index] = value.split("|")[1..3].map(&:strip)
              elsif value.match(/^data\|/i)
                data[index] = value.split("|").last.strip
              elsif value.strip.match(/^crm\|/i)
                crms[index] = value.split("|").last.strip
              end
            end

            unit_configuration_name = (row.field(4).to_s.strip rescue nil) if row.field(4).to_s.strip.present?
            unit_name = (row.field(5).to_s.strip rescue nil) if row.field(5).to_s.strip.present?
            floor = (row.field(6).to_s.strip.to_i rescue nil) if row.field(6).to_s.strip.present?
            floor_order = (row.field(7).to_s.strip.to_i rescue nil) if row.field(7).to_s.strip.present?
            carpet = (row.field(8).to_s.strip.to_f.round(2) rescue nil) if row.field(8).to_s.strip.present?
            saleable = (row.field(9).to_s.strip.to_f.round(2) rescue nil) if row.field(9).to_s.strip.present?
            base_rate = (row.field(10).to_s.strip.to_f rescue nil) if row.field(10).to_s.strip.present?
            floor_rise = (row.field(11).to_s.strip.to_f rescue nil) if row.field(11).to_s.strip.present?
            status = (row.field(12).to_s.strip rescue nil) if row.field(12).to_s.strip.present?
            bedrooms = (((row.field(13).to_s.strip.presence || 2).to_i) rescue nil) if row.field(13).to_s.strip.present?
            bathrooms = (((row.field(14).to_s.strip.presence || 2).to_i) rescue nil) if row.field(14).to_s.strip.present?
            unit_facing_direction = (row.field(15).to_s.strip rescue nil) if row.field(15).to_s.strip.present?
            erp_id = (row.field(16).to_s.strip rescue nil) if row.field(16).to_s.strip.present?
            blocking_amount = (row.field(17).to_s.strip.to_f rescue nil) if row.field(17).to_s.strip.present?

            project = project_unit.project
            project_tower = project_unit.project_tower

            if project_unit.status.in?(%w(available not_available))
              if status.present?
                _status = STATUS[status]
                unless _status
                  (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push("Status not supported for bulk update: #{row.field(1)}")).uniq
                  bur.failure_count += 1
                  next
                end
                project_unit.status = _status
              end
            end

            project_unit.name = unit_name if unit_name.present?
            project_unit.new_base_rate = base_rate.to_f if base_rate.present?
            project_unit.bedrooms = bedrooms.to_f if bedrooms.present?
            project_unit.bathrooms = bathrooms.to_f if bathrooms.present?
            project_unit.carpet = carpet.to_f if carpet.present?
            project_unit.saleable = saleable.to_f if saleable.present?
            project_unit.floor = floor if floor.present?
            project_unit.floor_order = floor_order if floor_order.present?
            project_unit.unit_facing_direction = unit_facing_direction if unit_facing_direction.present?
            if erp_id.present?
              project_unit.erp_id = erp_id
              project_unit.selldo_id = erp_id
            end
            project_unit.new_floor_rise = floor_rise.to_f if floor_rise.present?
            project_unit.new_blocking_amount = blocking_amount if blocking_amount.present?

            if unit_configuration_name.present? && project_unit.unit_configuration_name != unit_configuration_name
              unit_configuration = UnitConfiguration.where(project_id: project.id).where({'$and': [
                {data_attributes: {'$elemMatch': {n: 'name', v: unit_configuration_name }}},
                {data_attributes: {'$elemMatch': {n: 'saleable', v: project_unit.saleable}}},
                {data_attributes: {'$elemMatch': {n: 'carpet', v: project_unit.carpet}}}
              ]}).first
              unless unit_configuration.present?
                unit_configuration = UnitConfiguration.new(name: unit_configuration_name, project_id: project.id, saleable: project_unit.saleable, carpet: project_unit.carpet, booking_portal_client_id: booking_portal_client.id)
                unless unit_configuration.save
                  (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push(*unit_configuration.errors.full_messages.map{ |er| "Unit Configuration: " + er })).uniq
                  bur.failure_count += 1 if bur.upload_errors.where(row: row.fields).present?
                  next
                end
              end
              project_unit.unit_configuration = unit_configuration
              project_unit.unit_configuration_name = unit_configuration_name
            end

            # Update costs
            costs.each do |index, arr|
              if row[index].to_s.strip.present?
                if _cost = project_unit.costs.where(category: arr[0], key: arr[1].gsub(/[\W_]+/i, "_").downcase).first.presence
                  _cost["new_#{arr[2].presence || 'absolute_value'}"] = row[index]
                else
                  _cost = project_unit.costs.build(category: arr[0], name: arr[1], absolute_value: 0, key: arr[1].gsub(/[\W_]+/i, "_").downcase)
                  _cost["new_#{arr[2].presence || 'absolute_value'}"] = row[index]
                end
              end
            end
            # Update data
            data.each do |index, name|
              if row[index].to_s.strip.present?
                if _data = project_unit.data.where(key: name.gsub(/[\W_]+/i, "_").downcase).first.presence
                  _data.assign_attributes(new_absolute_value: row[index].to_f)
                else
                  project_unit.data.build(name: name, absolute_value: 0, new_absolute_value: row[index].to_f, key: name.gsub(/[\W_]+/i, "_").downcase)
                end
              end
            end
            # Update crm ids
            crms.each do |index, crm_id|
              if row[index].to_s.strip.present?
                _crm = Crm::Base.where(id: crm_id).first
                if _crm
                  if tpr = project_unit.third_party_references.where(crm_id: _crm.id).first.presence
                    tpr.assign_attributes(reference_id: row[index].to_s.strip)
                  else
                    project_unit.third_party_references.build(crm_id: _crm.id, reference_id: row[index].to_s.strip)
                  end
                else
                  project_unit.errors.add :base, 'Crm not registered with the system.'
                end
              end
            end

            if project_unit.save
              bur.success_count += 1
            else
              cost_errors = project_unit.costs.collect{|cost| [cost.errors.to_a.collect{|e| "Key - " + cost.key + ", Category - " + cost.category + ", Error - " + e}] if !cost.valid?}.compact.flatten
              project_unit.errors.delete(:costs)

              data_errors = project_unit.data.collect{|data| [data.errors.to_a.collect{|e| "Key - " + data.key + ", Error - " + e}] if !data.valid?}.compact.flatten
              project_unit.errors.delete(:data)

              (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push(*(project_unit.errors.full_messages + cost_errors + data_errors))).uniq
              bur.failure_count += 1
            end
          rescue => e
            bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push(["Exception: #{e.message}"] + e.backtrace)
            bur.failure_count += 1 if bur.upload_errors.where(row: row.fields).present?
          end
        else
          (bur.upload_errors.find_or_initialize_by(row: row.fields).messages << "Project Unit with id: #{unit_id} is not present in the system").uniq
          bur.failure_count += 1
        end
      end
    end

    def validate_headers(headers)
      if headers
        unless headers.compact.map(&:strip).slice(0, 18) == correct_headers
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
