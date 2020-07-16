module Crm::BaseHelper
  def custom_crms_path
    current_user.buyer? ? '' : admin_crm_base_index_path
  end
end
