require 'net/http'
class SelldoReceiptPusher
  include Sidekiq::Worker

  def perform(receipt_id, timestamp)
    receipt = Receipt.find(receipt_id)
    user = receipt.user
    instrument_date = receipt.issued_date || receipt.created_at
    params = {
      api_key: ENV_CONFIG[:selldo][:api_key],
      lead_id: user.lead_id,
      unit_id: receipt.project_unit_id.to_s,
      mode_of_transfer: receipt.payment_mode,
      instrument_date: instrument_date.strftime("%d-%m-%Y"),
      bank_name: receipt.issuing_bank,
      branch_name: receipt.issuing_bank_branch,
      instrument_no: receipt.payment_identifier,
      payment_type: receipt.payment_type,
      remarks: receipt.comments,
      payment_amount: receipt.total_amount
    }
    base_url = Rails.env.production? ? "https://app.sell.do" : (Rails.env.staging? ? "http://app.sell.do" : "http://localhost:8888")
    RestClient.post(base_url + "/api/leads/add_payment", params.to_json, { content_type: :json, accept: :json })
  end
end
