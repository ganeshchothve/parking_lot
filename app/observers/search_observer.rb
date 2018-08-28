class SearchObserver < Mongoid::Observer
  def after_create search
    SelldoLeadUpdater.perform_async(search.user_id.to_s, "unit_browsing")
  end

  def after_save search
    if search.project_unit_id_changed? && search.project_unit_id.present?
      SelldoLeadUpdater.perform_async(search.user_id.to_s, "unit_selected")
    end

    if search.project_unit_id_was.present? && search.project_unit_id.blank?
      ProjectUnitUnholdWorker.new.perform(search.project_unit_id_was.to_s)
    end
  end
end
