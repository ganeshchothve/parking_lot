module BulkUpload
  class ChannelPartnerUser < Base
    def initialize(bulk_upload_report)
      super(bulk_upload_report)
      @correct_headers = ['Company Id', 'First Name', 'Last Name', 'Phone', 'Email', 'Rera', 'Channel Partner Manager Phone']
    end

    def process_csv(csv)
      csv.each do |row|
        email = row.field(4).to_s.strip if row.field(4).to_s.strip.present?
        if row.field(3).to_s.strip.present?
          _phone = Phonelib.parse(row.field(3).to_s.strip)
          phone = (_phone.country_code == '91' && _phone.sanitized.length == 10 ? "+91#{_phone.sanitized}" : "+#{_phone.sanitized}")
        end
        if row.field(0).to_s.strip.present?
          partner_company = ::ChannelPartner.where(id: row.field(0).to_s.strip).first
          if partner_company.present?
            attrs = {}
            attrs[:first_name] = row.field(1).to_s.strip
            attrs[:last_name] = row.field(2).to_s.strip
            attrs[:email] = email if email.present?
            attrs[:phone] = phone if phone.present?
            attrs[:rera_id] = row.field(5).to_s.strip
            if m_phone = row.field(6).to_s.strip.presence
              _manager_phone = Phonelib.parse(m_phone)
              manager_phone = (_manager_phone.country_code == '91' && _manager_phone.sanitized.length == 10 ? "+91#{_manager_phone.sanitized}" : "+#{_manager_phone.sanitized}")
              manager = User.where(phone: manager_phone, role: {'$in': ['cp']}).first if manager_phone.present?
              if manager
                attrs[:manager_id] = manager.id
                attrs[:channel_partner_id] = partner_company.id
                attrs[:role] = 'channel_partner'
                user = User.new(attrs)
                if user.save
                  bur.success_count += 1
                else
                  (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push(*user.errors.full_messages)).uniq
                  bur.failure_count += 1
                end
              else
                (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push("Channel partner Manager not found with Phone no: #{m_phone}")).uniq
                bur.failure_count += 1
              end
            else
              (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push("Channel partner Manager Phone Number not found")).uniq
              bur.failure_count += 1
            end
          end
        end
      end
    end

  end
end
