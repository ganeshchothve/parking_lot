class ProjectUnitBookingService

  attr_reader :project_unit

  def initialize id
    @project_unit = ProjectUnit.find id
  end

  def send_for_negotiation
    booking_detail = create_booking_detail "under_negotiation"
    booking_detail_scheme = self.project_unit.booking_detail_scheme
    booking_detail_scheme.status = "under_negotiation"
    booking_detail_scheme.booking_detail_id = booking_detail.id
    booking_detail_scheme.save!

    self.project_unit.status = "under_negotiation"
    self.project_unit.save(validate: false)
  end

  def book
    if project_unit.status == "hold"
      booking_detail = self.create_booking_detail self.booking_detail_status
      self.create_or_update_booking_detail_scheme booking_detail
      self.project_unit.status = booking_detail.status
      self.project_unit.save(validate: false)
    elsif %w[booked_confirmed booked_tentative blocked].include?(project_unit.status)
      booking_detail = self.create_booking_detail project_unit.status
      self.create_or_update_booking_detail_scheme booking_detail
    end
  end

  def booking_detail_scheme_status
    booking_detail_scheme = self.project_unit.booking_detail_scheme
    if booking_detail_scheme.present? && booking_detail_scheme.status == "draft" && booking_detail_scheme.editable_payment_adjustments_present?
        "under_negotiation"
    else
      "approved"
    end
  end

  def booking_detail_status
    if self.booking_detail_scheme_status == "approved"
      if self.project_unit.pending_balance({strict: true}) <= 0
        'booked_confirmed'
      elsif self.project_unit.total_amount_paid > self.project_unit.blocking_amount
        'booked_tentative'
      elsif self.project_unit.total_tentative_amount_paid >= self.project_unit.blocking_amount
        'blocked'
      else
        self.project_unit.status
      end
    else
      "under_negotiation"
    end
  end

  def create_booking_detail status
    if project_unit.booking_detail.blank?
      BookingDetail.create(project_unit_id: self.project_unit.id, user_id: self.project_unit.user_id, receipt_ids: self.project_unit.receipt_ids, user_kyc_ids: self.project_unit.user_kyc_ids, primary_user_kyc_id: self.project_unit.primary_user_kyc_id, status: status, manager_id: self.project_unit.user.manager_id)
    else
      project_unit.booking_detail.update(user_id: self.project_unit.user_id, receipt_ids: self.project_unit.receipt_ids, user_kyc_ids: self.project_unit.user_kyc_ids, primary_user_kyc_id: self.project_unit.primary_user_kyc_id, status: status, manager_id: self.project_unit.user.manager_id)
    end
    project_unit.booking_detail
  end

  def create_or_update_booking_detail_scheme booking_detail
    booking_detail_scheme = self.project_unit.booking_detail_scheme

    if booking_detail_scheme.blank?
      scheme = self.project_unit.project_tower.default_scheme

      booking_detail_scheme = BookingDetailScheme.create!(
        derived_from_scheme_id: scheme.id,
        booking_detail_id: booking_detail.id,
        created_by_id: self.project_unit.user.id,
        booking_portal_client_id: scheme.booking_portal_client_id,
        cost_sheet_template_id: scheme.cost_sheet_template_id,
        payment_schedule_template_id: scheme.payment_schedule_template_id,
        payment_adjustments: scheme.payment_adjustments.collect(&:clone).collect{|record| record.editable = false},
        project_unit_id: self.project_unit.id
      )
    end

    booking_detail_scheme.event = self.booking_detail_scheme_status
    booking_detail_scheme.booking_detail_id = booking_detail.id

    if booking_detail_scheme.event == "approved"
      booking_detail_scheme.approved_by_id = self.project_unit.user.id
    end

    booking_detail_scheme.save!
  end
end
