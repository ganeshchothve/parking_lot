class ProjectUnitSwapService

  def initialize project_unit_id, alternate_project_unit_id
    @project_unit = ProjectUnit.find project_unit_id
    @alternate_project_unit = ProjectUnit.find alternate_project_unit_id
  end

  def swap
    if(@alternate_project_unit.status == "available" || (@alternate_project_unit.status == "hold" && @alternate_project_unit.user_id == @project_unit.user_id))
      existing_receipts = @project_unit.receipts.in(status:["success","clearance_pending"]).asc(:created_at).to_a
      existing_receipts.each{|x| x.project_unit_id=nil; x.comments ||=""; x.comments+= "Unit Swapped by user. Original Unit ID: #{@project_unit.id.to_s} So cancelling these receipts"; x.status="cancelled";x.save}
      primary_user_kyc = @project_unit.primary_user_kyc
      booking_detail = @project_unit.booking_detail
      user_kycs = @project_unit.user_kycs
      user = @project_unit.user

      @project_unit[:swap_request_initiated] = true
      @project_unit.make_available
      @project_unit.save!

      booking_detail.reload
      booking_detail[:swap_request_initiated] = true
      booking_detail.status ="swapped"
      booking_detail.save

      @alternate_project_unit.primary_user_kyc_id = primary_user_kyc.id
      @alternate_project_unit.user_kycs = user_kycs
      @alternate_project_unit.status = "hold"
      @alternate_project_unit.user = user
      @alternate_project_unit.save!

      existing_receipts.each do |old_receipt|
        new_receipt = old_receipt.clone
        new_receipt.comments = "Receipt generated for Swapped Unit. Original Receipt ID: #{old_receipt.id.to_s}"
        new_receipt.status="success"
        new_receipt.project_unit = @alternate_project_unit
        new_receipt.save!
      end
      @project_unit.unset(:swap_request_initiated)
      booking_detail.unset(:swap_request_initiated)
    else
      puts "error. #{@alternate_project_unit.name} is #{@alternate_project_unit.status}"
    end
  end

end
