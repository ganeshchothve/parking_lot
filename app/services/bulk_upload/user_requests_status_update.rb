module BulkUpload
  class UserRequestsStatusUpdate < Base
    STATUS = {
      'Approved' => 'processing',
      'Rejected' => 'rejected'
    }

    def initialize(bulk_upload_report)
      super(bulk_upload_report)
      @correct_headers = ['Request Id', 'Status', 'Comments']
    end

    def process_csv(csv)
      csv.each do |row|
        status = STATUS[row.field(1).to_s.strip]
        unless status
          (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push("Status not supported for bulk update: #{row.field(1)}")).uniq
          bur.failure_count += 1
          next
        end

        user_request = ::UserRequest.where(booking_portal_client_id: bur.booking_portal_client_id, id: row.field(0).to_s.strip).first if row.field(0).to_s.strip.present?
        if user_request
          attrs = {}
          attrs[:event] = status
          attrs[:notes_attributes] = [{note: row.field(2).to_s.strip, creator: bur.uploaded_by}] if row.field(2).to_s.strip.present?
          attrs[:resolved_by] = bur.uploaded_by

          if user_request.update_attributes(attrs)
            bur.success_count += 1
          else
            (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push(*user_request.errors.full_messages)).uniq
            bur.failure_count += 1
          end
        else
          (bur.upload_errors.find_or_initialize_by(row: row.fields).messages << 'User Request not found').uniq
          bur.failure_count += 1
        end
      end
    end
  end
end

