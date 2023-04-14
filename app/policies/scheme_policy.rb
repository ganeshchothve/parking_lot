class SchemePolicy < ApplicationPolicy
  # def index? def create? def permitted_attributes from ApplicationPolicy

  def new?
    index? 
  end

  def edit?
    create?
  end

  def update?
    edit?
  end

  def approve_via_email?
    edit?
  end

  def payment_adjustments_for_unit?
    user.active_channel_partner?
  end
end
