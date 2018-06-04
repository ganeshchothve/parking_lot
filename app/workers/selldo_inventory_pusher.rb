require 'net/http'
class SelldoInventoryPusher
  include Sidekiq::Worker

  def perform(project_unit_status, project_unit_id, timestamp)
    project_unit = ProjectUnit.find(project_unit_id)
    user = project_unit.user
    user_kycs = [project_unit.primary_user_kyc] + project_unit.user_kycs
    params = {
      api_key: ENV_CONFIG['selldo']['api_key'],
      lead_id: user.lead_id,
      stage: project_unit_status,
      booking_date: timestamp,
      unit_id: project_unit.selldo_id,
      project_id: project_unit.project_id.to_s
    }
    params["applicants"] = []
    user_kycs.each do |kyc|
      params["applicants"] << {name: kyc.name, email: kyc.email, phone: kyc.phone, pan_no: kyc.pan_number}
    end
    RestClient.post("https://app.sell.do/api/leads/add_booking", params)
  end
end
