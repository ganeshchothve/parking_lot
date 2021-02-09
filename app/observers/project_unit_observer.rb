class ProjectUnitObserver < Mongoid::Observer
  def before_validation project_unit
    #project_unit.agreement_price = project_unit.calculate_agreement_price.round
    #project_unit.all_inclusive_price = project_unit.calculate_all_inclusive_price.round
    #if project_unit.agreement_price_changed?
    #  project_unit.booking_price = (project_unit.agreement_price * project_unit.booking_price_percent_of_agreement_price).round
    #end
  end
end
