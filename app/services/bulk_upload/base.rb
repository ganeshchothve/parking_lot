module BulkUpload
  class Base

    attr_reader :bur, :correct_headers

    def initialize(bulk_upload_report)
      @bur = bulk_upload_report
      @bur.success_count = @bur.failure_count = 0
    end

    def upload
      file_url = bur.asset.try(:file).try(:url)
      if file_url
        begin
          csv = CSV.new(open(file_url), headers: true).read
          if validate_headers(csv.headers)
            if csv.count > 0
              bur.total_rows = csv.count
              process_csv(csv)
            else
              err_msg = 'No data found'
              err = bur.upload_errors.where(messages: err_msg).first
              bur.upload_errors.build(messages: [err_msg]) unless err
            end
          else
            bur.total_rows = bur.failure_count = csv.count
          end
        rescue StandardError => e
          Rails.logger.error "[#{self.class.name}] Errors: #{e.message}, Backtrace: #{e.backtrace.join('\n')}"
        end
      else
        err_msg = 'No file found'
        err = bur.upload_errors.where(messages: err_msg).first
        bur.upload_errors.build(messages: [err_msg]) unless err
      end
      unless bur.save
        Rails.logger.error "[#{self.class.name}] Errors: #{bur.errors.full_messages.join(', ')}"
      end
    rescue StandardError => e
      Rails.logger.error "[#{self.class.name}] Errors: #{e.message}, Backtrace: #{e.backtrace.join('\n')}"
    end

    def validate_headers(headers)
      if headers
        unless headers.compact.map(&:strip) == correct_headers
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

