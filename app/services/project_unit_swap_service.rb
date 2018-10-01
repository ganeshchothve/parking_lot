class ProjectUnitSwapService

  def initialize project_unit_id, alternate_project_unit_id
    @project_unit = ProjectUnit.find project_unit_id
    @alternate_project_unit = ProjectUnit.find alternate_project_unit_id
  end

  def swap
    if(@alternate_project_unit.status == "available" || (@alternate_project_unit.status == "hold" && @alternate_project_unit.user_id == @project_unit.user_id))

      existing_receipts = @project_unit.receipts.in(status:["success", "clearance_pending", "pending"]).asc(:total_amount)
      existing_receipts_json = existing_receipts.as_json
      existing_receipts.each do |receipt|
        receipt.project_unit_id = nil
        receipt.comments ||= ""
        receipt.comments += "Unit Swapped by user. Original Unit ID: #{@project_unit.id.to_s} So cancelling these receipts"
        receipt.swap_request_initiated = true
        receipt.event = "cancel"
        receipt.save
      end

      primary_user_kyc = @project_unit.primary_user_kyc
      booking_detail = @project_unit.booking_detail
      user_kycs = @project_unit.user_kycs
      user = @project_unit.user

      @project_unit.processing_swap_request = true
      @project_unit.make_available
      @project_unit.save!

      booking_detail.reload
      booking_detail[:swap_request_initiated] = true
      booking_detail.status = "swapped"
      booking_detail.save

      @alternate_project_unit.primary_user_kyc_id = primary_user_kyc.id
      @alternate_project_unit.user_kycs = user_kycs
      @alternate_project_unit.status = "hold"
      @alternate_project_unit.user = user
      @alternate_project_unit.selected_scheme_id = @project_unit.scheme.id
      @alternate_project_unit.save!

      existing_receipts_json.each do |old_receipt|
        cloned_json = old_receipt.clone
        cloned_json.delete "receipt_id"
        cloned_json.delete "_id"
        cloned_json.delete "order_id"
        cloned_json.delete "booking_detail_id"
        cloned_json.delete "created_at"
        cloned_json.delete "updated_at"

        new_receipt = Receipt.new(cloned_json)
        new_receipt.comments = "Receipt generated for Swapped Unit. Original Receipt ID: #{old_receipt["id"].to_s}"
        new_receipt.project_unit = @alternate_project_unit
        new_receipt.swap_request_initiated = true
        new_receipt.save!
      end
      booking_detail.unset(:swap_request_initiated)
      {status: "success"}
    else
      {status: "error", error: "#{@alternate_project_unit.name} is #{@alternate_project_unit.status}"}
    end
  end

end