module BulkUpload
  class ReceiptsStatusUpdate < Base
    STATUS = {
      'Success' => 'success',
      'Clearance Pending' => 'clearance_pending',
      'Failed' => 'failed',
      'Refunded' => 'refund'
    }

    def initialize(bulk_upload_report)
      super(bulk_upload_report)
      @correct_headers = ["Id", "Status", "Processed On", "Comments", "Payment Identifier", "Transaction ID"]
    end

    def process_csv(csv)
      csv.each do |row|
        status = STATUS[row.field(1).to_s.strip]
        unless status
          (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push("Status not supported for bulk update: #{row.field(1)}")).uniq
          bur.failure_count += 1
          next
        end

        receipt = ::Receipt.where(id: row.field(0).to_s.strip).first if row.field(0).to_s.strip.present?
        if receipt
          attrs = {}
          attrs[:event] = status
          if processed_on = row.field(2).to_s.strip.presence
            begin
              attrs[:processed_on] = Date.strptime(processed_on, '%d/%m/%Y')
            rescue ArgumentError => e
              (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push("#{row.headers.fetch(2)}: Invalid Date Format")).uniq
              bur.failure_count += 1
              next
            end
          end
          attrs[:comments] = row.field(3).to_s.strip if row.field(3).to_s.strip.present?
          attrs[:payment_identifier] = row.field(4).to_s.strip if row.field(4).to_s.strip.present?
          attrs[:tracking_id] = row.field(5).to_s.strip if row.field(5).to_s.strip.present?

          if receipt.update_attributes(attrs)
            bur.success_count += 1
          else
            (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push(*receipt.errors.full_messages)).uniq
            bur.failure_count += 1
          end
        else
          (bur.upload_errors.find_or_initialize_by(row: row.fields).messages << I18n.t("controller.receipts.alert.not_found")).uniq
          bur.failure_count += 1
        end
      end
    end
  end
end
