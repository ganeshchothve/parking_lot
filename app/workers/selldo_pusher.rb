require 'net/http'
class SelldoPusher
  include Sidekiq::Worker

  def perform(project_unit_status, project_unit_id, timestamp)
    project_unit = ProjectUnit.find(project_unit_id)
    user = project_unit.user
    user_kycs = project_unit.user_kycs
    params = {
      api_key: "bcdd92826cf283603527bd6d832d16c4",
      lead_id: user.lead_id,
      stage: project_unit_status,
      booking_date: timestamp,
      unit_id: project_unit.selldo_id
    }
    params["applicants"] = []
    user_kycs.each do |kyc|
      params["applicants"] << {name: kyc.name, email: kyc.email, phone: kyc.phone, pan_no: kyc.pan_number}
    end
    RestClient.post("https://sn1.sell.do/api/leads/add_booking", params)
  end
end
