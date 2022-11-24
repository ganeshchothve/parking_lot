module BulkUpload
  class Receipt < Base
    def initialize(bulk_upload_report)
      super(bulk_upload_report)
      @correct_headers = ['ERP Id', 'Selldo Lead Id', 'Phone', 'Email', 'Payment Mode', 'Payment Type', 'Token Type', 'Cheque Number / Transaction Identifier', 'Issuing Bank', 'Branch', 'Date of Issuance', 'Total Amount', 'Status', 'Date of Clearance', 'Time Slot Id']
    end

    def process_csv(csv)
      booking_portal_client = bur.client
      if project = bur.project.presence
        modes = {
          'Cheque' => 'cheque',
          'RTGS' => 'rtgs',
          'IMPS' => 'imps',
          'Card Swipe' => 'card_swipe',
          'NEFT' => 'neft',
          'Online' => 'online'
        }
        statuses = {
          'Pending' => 'pending',
          'Clearance Pending' => 'clearance_pending',
          'Success' => 'success',
          'Failed' => 'failed',
          'Cancelled' => 'cancelled',
          'Available for Refund' => 'available_for_refund',
          'Refunded' => 'refunded'
        }
        payment_types = {
          'Token' => 'token',
          'Agreement' => 'agreement',
          'Stamp Duty' => 'stamp_duty'
        }

        csv.each do |row|
          erp_id = row.field(0).to_s.strip
          if erp_id
            query = []
            query << {lead_id: row.field(1).to_s.strip} if row.field(1).to_s.strip.present?
            if row.field(2).to_s.strip.present?
              _phone = Phonelib.parse(row.field(2).to_s.strip)
              phone = (_phone.country_code == '91' && _phone.sanitized.length == 10 ? "+91#{_phone.sanitized}" : "+#{_phone.sanitized}")
              query << {phone: phone}
            end
            if row.field(3).to_s.strip.present?
              email = row.field(3).to_s.strip
              query << {email: email}
            end

            if User.or(query).count > 1
              (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push("More than 1 users exist with this Selldo lead id/ phone/ email")).uniq
              bur.failure_count += 1
              next
            end

            user = User.or(query).where(booking_portal_client_id: bur.booking_portal_client_id).first
            if user
              if lead = user.leads.where(project_id: bur.project_id).first
                attrs = {}
                attrs[:lead_id] = lead.id
                attrs[:user_id] = user.id
                attrs[:project_id] = project.id
                attrs[:creator_id] = bur.uploaded_by.id
                attrs[:erp_id] = erp_id

                if issued_date = row.field(10).to_s.strip.presence
                  begin
                    attrs[:issued_date] = Date.strptime(issued_date, '%d-%b-%y')
                  rescue ArgumentError => e
                    (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push("#{row.headers.fetch(10)}: Invalid Date Format")).uniq
                    bur.failure_count += 1
                    next
                  end
                end
                if processed_on = row.field(13).to_s.strip.presence
                  begin
                    attrs[:processed_on] = Date.strptime(processed_on, '%d-%b-%y')
                  rescue ArgumentError => e
                    (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push("#{row.headers.fetch(13)}: Invalid Date Format")).uniq
                    bur.failure_count += 1
                    next
                  end
                end
                _mode = row.field(4).to_s.strip
                if _mode && (mode = modes[_mode].presence)
                  attrs[:payment_mode] = mode
                else
                  (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push('Invalid Payment mode')).uniq
                  bur.failure_count += 1
                  next
                end
                _payment_type = row.field(5).to_s.strip
                if _payment_type && (payment_type = payment_types[_payment_type].presence)
                  attrs[:payment_type] = payment_type
                else
                  (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push('Invalid Payment type')).uniq
                  bur.failure_count += 1
                  next
                end
                _token_type = row.field(6).to_s.strip
                if _token_type && token_type = project.token_types.where(name: _token_type).all.select{|tt| tt.incrementor_exists?}.first
                  attrs[:token_type_id] = token_type.id
                else
                  (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push('Active Token Type not found')).uniq
                  bur.failure_count += 1
                  next
                end
                _status = row.field(12).to_s.strip
                if _status && (status = statuses[_status].presence)
                  attrs[:status] = status
                else
                  (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push('Invalid Payment status')).uniq
                  bur.failure_count += 1
                  next
                end
                attrs[:payment_identifier] = row.field(7).to_s.strip if row.field(7).to_s.strip.present?
                attrs[:issuing_bank] = row.field(8).to_s.strip if row.field(8).to_s.strip.present?
                attrs[:issuing_bank_branch] = row.field(9).to_s.strip if row.field(9).to_s.strip.present?
                attrs[:total_amount] = row.field(11).to_s.strip if row.field(11).to_s.strip.present?

                #time slot
                if time_slot_id = row.field(14).to_s.strip.presence
                  if time_slot = project.time_slots.where(number: time_slot_id).first.presence
                    attrs[:time_slot_id] = time_slot.id
                  else
                    (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push("#{row.headers.fetch(14)}: #{time_slot_id} not found")).uniq
                    bur.failure_count += 1
                    next
                  end
                end
                attrs[:booking_portal_client] = booking_portal_client
                receipt = ::Receipt.new(attrs)
                if receipt.save
                  bur.success_count += 1
                else
                  (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push(*receipt.errors.full_messages)).uniq
                  bur.failure_count += 1
                end
              else
                (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push('Lead not found for this project')).uniq
                bur.failure_count += 1
              end
            else
              (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push('User not found')).uniq
              bur.failure_count += 1
            end
          else
            (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push('Erp Id is missing')).uniq
            bur.failure_count += 1
          end
        end
      else
        err_msg = 'Project not found on Bulk Upload'
        err = bur.upload_errors.where(messages: err_msg).first
        bur.upload_errors.build(messages: [err_msg]) unless err
        bur.failure_count = csv.count
      end
    end

  end
end
