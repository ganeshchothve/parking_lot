class SearchObserver < Mongoid::Observer
  def after_save search
    if search.project_unit_id_was.present? && search.project_unit_id.blank?
      ProjectUnitUnholdWorker.new.perform(search.project_unit_id_was.to_s)
    end
  end
end
