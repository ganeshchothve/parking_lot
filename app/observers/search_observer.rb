class SearchObserver < Mongoid::Observer
  def after_create search
    SelldoLeadUpdater.perform_async(search.user_id.to_s, {stage: "unit_browsing"})
  end

  def before_save search
    if search.project_tower_id.blank? && search.project_unit_id.present?
      search.project_tower_id = search.project_unit.project_tower_id
    end
  end

  def after_save search
    if search.project_unit_id_changed? && search.project_unit_id.present?
      SelldoLeadUpdater.perform_async(search.user_id.to_s, {stage: "unit_selected"})
    end

    if search.project_unit_id_was.present? && search.project_unit_id.blank?
      ProjectUnitUnholdWorker.new.perform(search.project_unit_id_was.to_s)
    end
  end
end
