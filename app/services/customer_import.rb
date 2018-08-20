module CustomerImport
  def self.update(filepath, test)
    count = 0
    CSV.foreach(filepath) do |row|
      unless count == 0
        first_name = row[0]
        last_name = row[1]
        email = row[2]
        phone = row[3]
        manager = row[4]
        customer = User.where(role: "customer").or({email: email}, {phone: phone}).first
        if customer.present?
          customer.update({first_name: first_name, last_name: last_name, phone: phone, email: email, manager_id: manager})
        else
          User.create({first_name: first_name, last_name: last_name, phone: phone, email: email, manager_id: manager})
        end
      end
    end
  end
end
