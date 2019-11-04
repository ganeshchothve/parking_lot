module ChecklistHelper

  def custom_checklists_path
    current_user.buyer? ? '' : admin_checklists_path
  end
end