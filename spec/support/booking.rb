module Booking
  def booking_under_negotiation (user,project_unit = nil, receipt = nil)
    project_unit ||= create(:project_unit)
    kyc = user.user_kycs.first || create(:user_kyc, creator_id: user.id, user: user)
    project_unit.assign_attributes(user_id: user.id, primary_user_kyc_id: kyc.id, status: 'blocked')
    project_unit.save
    search = create(:search, user_id: user.id, project_unit_id: project_unit.id)
    booking_detail = create(:booking_detail, primary_user_kyc_id: project_unit.primary_user_kyc_id, project_unit_id: project_unit.id, user_id: user.id, search: search)
    @booking_detail_scheme = create(:booking_detail_scheme)
    booking_detail.under_negotiation!
    booking_detail
  end

  def book_project_unit(user, project_unit = nil, receipt = nil, status='blocked')
    project_unit ||= create(:project_unit)
    kyc = user.user_kycs.first || create(:user_kyc, creator_id: user.id, user: user)
    receipt_amount = project_unit.blocking_amount
    if status == 'booked_tentative'
      receipt_amount = receipt_amount + 10000
    elsif status == 'booked_confirmed'
      receipt_amount = project_unit.booking_price + 10000
    elsif status == 'hold'
      receipt_amount = nil
    end

    project_unit.assign_attributes(user_id: user.id, primary_user_kyc_id: kyc.id, status: status)
    project_unit.save
    search = create(:search, user_id: user.id, project_unit_id: project_unit.id)
    booking_detail = create(:booking_detail, primary_user_kyc_id: project_unit.primary_user_kyc_id, status: project_unit.status, project_unit_id: project_unit.id, user_id: user.id, search: search)
    booking_detail_scheme = create(:booking_detail_scheme, booking_detail: booking_detail, status: 'approved')
    if receipt_amount
      receipt = receipt ? receipt.set(booking_detail_id: booking_detail.id) : create(:check_payment, user_id: user.id, total_amount: receipt_amount, status: 'success', booking_detail_id: booking_detail.id)
    end
    booking_detail
  end

  def swap_request(user, project_unit=nil, receipt=nil, status='blocked', alternate_project_unit=nil)
    alternate_project_unit ||= create(:project_unit)
    booking_detail = book_project_unit(user, project_unit, receipt, status)
    create(:pending_user_request_swap, alternate_project_unit_id: alternate_project_unit.id, user_id: user.id, created_by_id: (User.where(role: 'admin').first || create(:admin) ), booking_detail_id: booking_detail.id, event: 'pending')
  end

  def scheme
    developer = create(:developer)
    project = create(:project, developer_id: developer.id)
    project_tower = create(:project_tower, project: project)
    project_unit = create(:project_unit, project_tower: project_tower, project: project)
    project_unit.status = 'draft'
    project_unit.save
    scheme = create(:scheme, project: project_unit.project, project_tower: project_unit.project_tower)
    scheme
  end
end
