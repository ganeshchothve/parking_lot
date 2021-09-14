module BulkUpload
  class Lead < Base
    def initialize(bulk_upload_report)
      super(bulk_upload_report)
      @correct_headers = ["Selldo Lead Id", "First Name", "Last Name", "Phone", "Email"]
    end

    def process_csv(csv)
      if bur.project_id.present?
        client = bur.uploaded_by.booking_portal_client
        csv.each do |row|
          query = []
          if row.field(4).to_s.strip.present?
            email = row.field(4).to_s.strip
            query << {email: email}
          end
          if row.field(3).to_s.strip.present?
            _phone = Phonelib.parse(row.field(3).to_s.strip)
            phone = (_phone.country_code == '91' && _phone.sanitized.length == 10 ? "+91#{_phone.sanitized}" : "+#{_phone.sanitized}")
            query << {phone: phone}
          end

          unless query.present?
            (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push("Phone or Email is required")).uniq
            bur.failure_count += 1
            next
          end

          query << {lead_id: row.field(0).to_s.strip} if row.field(0).to_s.strip.present?

          if (count = User.or(query).count) > 1
            (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push("More than 1 users exist with this Selldo lead id/ phone/ email")).uniq
            bur.failure_count += 1
            next
          end

          attrs = {}
          attrs[:lead_id] = row.field(0).to_s.strip
          attrs[:first_name] = row.field(1).to_s.strip
          attrs[:last_name] = row.field(2).to_s.strip
          attrs[:email] = email if email.present?
          attrs[:phone] = phone if phone.present?
          lead_attrs = attrs.clone
          attrs[:booking_portal_client_id] = client.id

          if count.zero?
            user = User.new(attrs)
            if user.save
              user.confirm #auto confirm user account
              create_lead(user, row, lead_attrs)
            else
              (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push(*user.errors.full_messages.map { |x| "User: #{x}" })).uniq
              bur.failure_count += 1
            end
          else
            create_lead(User.or(query).first, row, lead_attrs)
          end
        end
      else
        err_msg = 'Project not found on Bulk Upload'
        err = bur.upload_errors.where(messages: err_msg).first
        bur.upload_errors.build(messages: [err_msg]) unless err
        bur.failure_count = csv.count
      end
    end

    def create_lead(user, row, attrs = {})
      attrs[:project_id] = bur.project_id
      lead = user.leads.build(attrs)
      if lead.save
        bur.success_count += 1
      else
        (bur.upload_errors.find_or_initialize_by(row: row.fields).messages.push(*lead.errors.full_messages.map { |x| "Lead: #{x}" })).uniq
        bur.failure_count += 1
      end
    end
  end
end
