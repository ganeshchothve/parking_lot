module BulkUpload
  class ProjectUnitsUpdate < Base
    STATUS = {
      'Available' => 'available',
      'Not Available' => 'not_available',
    }

    def initialize(bulk_upload_report)
      super(bulk_upload_report)
      @correct_headers = ["Id", "Status", "Floor rise", "Base rate"]
    end

    def process_csv(csv)
      csv.each do |row|
        status = STATUS[row.field(1).to_s.strip]
        unless status
          (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push("Status not supported for bulk update: #{row.field(1)}")).uniq
          bur.failure_count += 1
          next
        end

        project_unit = ::ProjectUnit.where(id: row.field(0).to_s.strip).first if row.field(0).to_s.strip.present?
        if project_unit.present?
          if %w[available not_available error].include?(project_unit.status)
            attrs = {}
            attrs[:status] = status
            if row.field(2).present?
              attrs[:floor_rise] = row.field(2).to_f
            end

            if row.field(3).present?
              unless row.field(3).to_f.zero?
                attrs[:base_rate] = row.field(3).to_f
              else
                (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push("Base rate shoud be a number greater than 0")).uniq
                bur.failure_count += 1
                next
              end
            end

            if project_unit.update_attributes(attrs)
              bur.success_count += 1
            else
              (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push(*project_unit.errors.full_messages)).uniq
              bur.failure_count += 1
            end
          else
            (bur.upload_errors.find_or_initialize_by(row: row.fields).messages << "Current status of project unit cannot be changed - #{project_unit.status}").uniq
            bur.failure_count += 1
          end
        else
          (bur.upload_errors.find_or_initialize_by(row: row.fields).messages << "Project Unit with id: #{row.field(0)} is not present in the system").uniq
          bur.failure_count += 1
        end
      end
    end
  end
end
