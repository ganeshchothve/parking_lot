module CustomerImport
  def self.update(filepath, test)
    count = 0
    booking_portal_client = Client.first
    CSV.foreach(filepath) do |row|
      unless count == 0
        lead_id = row[0].strip
        first_name = row[1].present? ? row[1].strip : "Customer"
        last_name = row[2].present? ? row[2].strip : "."
        email = row[3].present? ? row[3].strip : ""
        phone = row[4].present? ? "+91#{row[4].strip}" : ""
        manager_email = row[4].present? ? row[4].strip : ""
        manager = User.nin(role: User.buyer_roles(booking_portal_client)).where(email: manager_email).first
        query = []
        query << {email: email} if email.present?
        query << {phone: phone} if phone.present?
        query << {lead_id: lead_id} if lead_id.present?
        customer = User.where(role: "customer").or(query).first
        if customer.present?
          # puts customer.id
          # customer.update({first_name: first_name, last_name: last_name, phone: phone, email: email, manager_id: manager})
        else
          user = User.new({lead_id: lead_id, first_name: first_name, last_name: last_name, phone: phone, email: email, booking_portal_client: booking_portal_client})
          user.manager = manager if manager.present?
          unless user.valid?
            puts "#{user.errors.full_messages} #{user.lead_id} #{user.name} #{user.email} #{user.phone}"
          end
          # user.skip_confirmation_notification!
          # puts "#{user.save} #{user.lead_id} #{user.name} #{user.email} #{user.phone}"
          # user.confirm
        end
      end
      count += 1
    end
  end
end
