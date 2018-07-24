module CustomerImport
  def self.update(filepath, test)
    count = 0
    CSV.foreach(filepath) do |row|
      unless count == 0
        first_name = row[0]
        last_name = row[1]
        email = row[2]
        phone = row[3]
        channel_partner = row[4]
        customer = User.where(role: "customer").or({email: email}, {phone: phone}).first
        if customer.present?
          customer.update({first_name: first_name, last_name: last_name, phone: phone, email: email, channel_partner_id: channel_partner})
        else
          User.create({first_name: first_name, last_name: last_name, phone: phone, email: email, channel_partner_id: channel_partner})
        end
      end
    end
  end
end



=begin

CSV.foreach("#{Rails.root}/customer.csv") do |row|
  name = row[0]
  phone = row[1]
  email = row[2]
  customer = User.where(role: "user").or({email: email}, {phone: phone}).first
  if customer.blank?
    customer = User.new(first_name: name.split(" ")[0], last_name: name.split(" ").last, phone: phone, email: email, role: "user")
  else
    customer.present?
    customer.channel_partner_id = BSON::ObjectId("5b24ebe2f7684a5b10706e08")
    puts customer.save
    puts customer.name
  end
end

=end
