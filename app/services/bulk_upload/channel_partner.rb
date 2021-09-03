module BulkUpload
  class ChannelPartner < Base
    def initialize(bulk_upload_report)
      super(bulk_upload_report)
      @correct_headers = ['First Name', 'Last Name', 'Phone', 'Company', 'Email', 'Pan', 'Aadhaar', 'Rera', 'Channel Partner Manager Phone']
    end

    def process_csv(csv)
      csv.each do |row|
        email = row.field(4).to_s.strip if row.field(4).to_s.strip.present?
        if row.field(2).to_s.strip.present?
          _phone = Phonelib.parse(row.field(2).to_s.strip)
          phone = (_phone.country_code == '91' && _phone.sanitized.length == 10 ? "+91#{_phone.sanitized}" : "+#{_phone.sanitized}")
        end
        attrs = {}
        attrs[:first_name] = row.field(0).to_s.strip
        attrs[:last_name] = row.field(1).to_s.strip
        attrs[:email] = email if email.present?
        attrs[:phone] = phone if phone.present?
        attrs[:company_name] = row.field(3).to_s.strip
        attrs[:pan_number] = row.field(5).to_s.strip
        attrs[:aadhaar] = row.field(6).to_s.strip
        attrs[:rera_id] = row.field(7).to_s.strip
        if m_phone = row.field(8).to_s.strip.presence
          _manager_phone = Phonelib.parse(m_phone)
          manager_phone = (_manager_phone.country_code == '91' && _manager_phone.sanitized.length == 10 ? "+91#{_manager_phone.sanitized}" : "+#{_manager_phone.sanitized}")
          manager = User.where(phone: manager_phone, role: {'$in': ['cp', 'cp_admin']}).first if manager_phone.present?
          if manager
            attrs[:manager_id] = manager.id
          else
            (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push("Channel partner Manager not found with Phone no: #{m_phone}")).uniq
          end
        end
        attrs[:interested_services] = ['Lead Management']

        cp = ::ChannelPartner.new(attrs)
        if cp.save
          bur.success_count += 1
        else
          (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push(*cp.errors.full_messages)).uniq
          bur.failure_count += 1
        end
      end
    end

  end
end
