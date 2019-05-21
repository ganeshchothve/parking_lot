require 'net/http'
class SelldoInventoryPusher
  include Sidekiq::Worker

  def perform(project_unit_status, project_unit_id, timestamp)
    project_unit = ProjectUnit.find(project_unit_id)
    user = project_unit.user
    booking_detail = project_unit.booking_detail
    user_kycs = booking_detail ? ([booking_detail.primary_user_kyc] + booking_detail.user_kycs) : []
    params = {
      api_key: project_unit.booking_portal_client.selldo_api_key,
      lead_id: user.lead_id,
      stage: project_unit_status,
      booking_date: timestamp,
      unit_id: project_unit.selldo_id,
      payment_schedule_id: nil,
      project_id: project_unit.project_id.to_s
    }
    params["applicants"] = []
    user_kycs.each do |kyc|
      params["applicants"] << {name: kyc.name, email: kyc.email, phone: kyc.phone, pan_no: kyc.pan_number}
    end
    RestClient.post("https://app.sell.do/api/leads/add_booking", params)
  end
end
