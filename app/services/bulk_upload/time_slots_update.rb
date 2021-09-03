module BulkUpload
  class TimeSlotsUpdate < Base
    def initialize(bulk_upload_report)
      super(bulk_upload_report)
      @correct_headers = ['Receipt Id', 'Slot Date', 'Time Slot']
    end

    def process_csv(csv)
      csv.each do |row|
        receipt_id = row.field(0).to_s.strip
        if receipt_id
          if receipt = ::Receipt.where(id: receipt_id).first.presence
            #time slot
            attrs = {}
            time_slot_attrs = {}
            if slot_date = row.field(1).to_s.strip.presence
              begin
                time_slot_attrs[:date] = Date.strptime(slot_date, '%d-%b-%y')
              rescue ArgumentError => e
                (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push("#{row.headers.fetch(1)}: Invalid Date Format")).uniq
                bur.failure_count += 1
                next
              end
            end
            if time_slot = row.field(2).to_s.strip.presence
              begin
                start_time, end_time = time_slot.split(' - ')
                time_slot_attrs[:start_time] = Time.use_zone(receipt.user.time_zone) { Time.zone.parse(start_time, time_slot_attrs[:date]) }
                time_slot_attrs[:end_time] = Time.use_zone(receipt.user.time_zone) { Time.zone.parse(end_time, time_slot_attrs[:date]) }
              rescue StandardError => e
                (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push("#{row.headers.fetch(2)}: #{e.message}")).uniq
                bur.failure_count += 1
                next
              end
            end
            attrs[:time_slot_attributes] = time_slot_attrs

            if receipt.update(attrs)
              bur.success_count += 1
            else
              (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push(*receipt.errors.full_messages)).uniq
              bur.failure_count += 1
            end
          else
            (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push('Receipt not found')).uniq
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
