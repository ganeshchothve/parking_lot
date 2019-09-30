class ChecklistObserver < Mongoid::Observer

  def after_validation checklist
    checklist.client.errors.add(:base, checklist.errors.to_a) if checklist.errors.present?
  end
end
