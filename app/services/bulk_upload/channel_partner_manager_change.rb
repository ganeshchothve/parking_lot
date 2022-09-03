module BulkUpload
  class ChannelPartnerManagerChange < Base
    def initialize(bulk_upload_report)
      super(bulk_upload_report)
      @correct_headers = ['Channel Partner Id', 'Channel Partner Manager Phone']
    end

    def process_csv(csv)
      csv.each do |row|
        channel_partner_id = row.field(0).to_s.strip
        if channel_partner_id.present? && (channel_partner = ::ChannelPartner.where(id: channel_partner_id).first.presence)
          attrs = {}
          if m_phone = row.field(1).to_s.strip.presence
            _manager_phone = Phonelib.parse(m_phone)
            manager_phone = (_manager_phone.country_code == '91' && _manager_phone.sanitized.length == 10 ? "+91#{_manager_phone.sanitized}" : "+#{_manager_phone.sanitized}")
            manager = User.where(phone: manager_phone, role: {'$in': ['cp', 'cp_admin']}).first if manager_phone.present?
            if manager
              attrs[:manager_id] = manager.id
            else
              (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push("Channel partner Manager not found with Phone no: #{m_phone}")).uniq
              next
            end
          end

          if channel_partner.update(attrs)
            bur.success_count += 1
          else
            (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push(*channel_partner.errors.full_messages)).uniq
            bur.failure_count += 1
          end
        else
          (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push('Channel Partner not found')).uniq
          bur.failure_count += 1
        end
      end
    end

  end
end
