module BulkUpload
  class TimeSlotsUpdate < Base
    def initialize(bulk_upload_report)
      super(bulk_upload_report)
      @correct_headers = ['Receipt Id', 'Time Slot Id']
    end

    def process_csv(csv)
      csv.each do |row|
        receipt_id = row.field(0).to_s.strip
        if receipt_id
          if receipt = ::Receipt.where(id: receipt_id).first.presence
            #time slot
            attrs = {}
            if time_slot_id = row.field(1).to_s.strip.presence
              if time_slot = receipt.project.time_slots.where(number: time_slot_id).first.presence
                attrs[:time_slot_id] = time_slot.id
              else
                (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push("#{row.headers.fetch(1)}: #{time_slot_id} not found")).uniq
                bur.failure_count += 1
                next
              end
            end

            if receipt.update(attrs)
              bur.success_count += 1
            else
              (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push(*receipt.errors.full_messages)).uniq
              bur.failure_count += 1
            end
          else
            (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push(I18n.t("controller.receipts.alert.not_found"))).uniq
            bur.failure_count += 1
          end
        else
          (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push('Receipt Id is missing')).uniq
          bur.failure_count += 1
        end
      end
    end

  end
end
