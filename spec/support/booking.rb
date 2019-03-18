module Booking

  def book_project_unit(user, project_unit=nil)
    project_unit ||= create(:project_unit)
    kyc = user.user_kycs.first || create(:user_kyc, creator_id: user.id, user: user)
    project_unit.assign_attributes(user_id: user.id, primary_user_kyc_id: kyc.id, status: 'blocked')
    project_unit.save
    booking_detail = create(:booking_detail, primary_user_kyc_id: project_unit.primary_user_kyc_id, status: project_unit.status, project_unit_id: project_unit.id, user_id: user.id)
    receipt = create(:check_payment, user_id: user.id, total_amount: project_unit.blocking_amount, project_unit_id: project_unit.id, status: 'success')
    booking_detail
  end

end