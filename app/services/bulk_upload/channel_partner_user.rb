module BulkUpload
  class ChannelPartnerUser < Base
    def initialize(bulk_upload_report)
      super(bulk_upload_report)
      @correct_headers = ['Company Id', 'First Name', 'Last Name', 'Phone', 'Email', 'Rera']
    end

    def process_csv(csv)
      csv.each do |row|
        email = row.field(4).to_s.strip if row.field(4).to_s.strip.present?
        if row.field(3).to_s.strip.present?
          _phone = Phonelib.parse(row.field(3).to_s.strip)
          phone = (_phone.country_code == '91' && _phone.sanitized.length == 10 ? "+91#{_phone.sanitized}" : "+#{_phone.sanitized}")
        end
        if row.field(0).to_s.strip.present?
          partner_company = ::ChannelPartner.where(booking_portal_client_id: bur.booking_portal_client_id, id: row.field(0).to_s.strip).first
          if partner_company.present?
            attrs = {}
            attrs[:first_name] = row.field(1).to_s.strip
            attrs[:last_name] = row.field(2).to_s.strip
            attrs[:email] = email if email.present?
            attrs[:phone] = phone if phone.present?
            attrs[:rera_id] = row.field(5).to_s.strip
            attrs[:manager_id] = partner_company.manager_id if partner_company.manager_id.present?
            attrs[:channel_partner_id] = partner_company.id
            attrs[:role] = 'channel_partner'
            attrs[:booking_portal_client_id] = partner_company.booking_portal_client_id
            user = User.new(attrs)
            if user.save
              bur.success_count += 1
            else
              (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push(*user.errors.full_messages)).uniq
              bur.failure_count += 1
            end
          else
            (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push("Partner Company Not Found"))
            bur.failure_count += 1
          end
        end
      end
    end

  end
end
