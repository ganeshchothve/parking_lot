class Buyer::SchemePolicy < SchemePolicy
  # def index? def new? def create? def edit? def update? def approve_via_email? def payment_adjustments_for_unit? def permitted_attributes? from SchemePolicy

  def index?
    true
  end
end
