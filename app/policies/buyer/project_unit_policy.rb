class Buyer::ProjectUnitPolicy < ProjectUnitPolicy
  # def ds? def show? new? def print? def export? def mis_report? def create? def update? def block? def make_available? def update_scheme? def update_co_applicants? def update_project_unit? def payment? def process_payment? def checkout? def send_under_negotiation? from ProjectUnitPolicy

  def index?
    current_client.enable_actual_inventory?(user) && user.buyer?
  end

  def edit?
    (record.status != 'hold' && record.user_id == user.id) if user.buyer?
  end

  def show?
    index?
  end

  def hold?
    valid = record.user.confirmed? && record.user.kyc_ready? && current_client.enable_actual_inventory?(user)
    if !valid
      @condition = "user_confirmation"
      return
    end
    valid &&= (record.user.project_units.where(status: 'hold').blank? && record.user_based_status(record.user) == 'available')
    if !valid
      @condition = "already_held"
      return
    end
    valid = (valid && record.user.allowed_bookings > record.user.booking_details.nin(status: %w[cancelled swapped]).count)
    if !valid
      @condition = "allowed_bookings"
      return
    end
    valid = (valid && record.user.unused_user_kyc_ids(record.id).present?)
    if !valid
      @condition = "user_kyc_allowed_bookings"
      return
    end
    _role_based_check(valid)
  end

  def permitted_attributes(_params = {})
    attributes = []
    attributes += (make_available? ? [:status] : [])
    attributes.uniq
  end

  private

  def _role_based_check(valid)
    valid = (valid && (record.user_id == user.id)) if user.buyer?
  end
end
