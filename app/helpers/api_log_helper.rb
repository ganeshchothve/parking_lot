module ApiLogHelper

  def custom_api_logs_path
    current_user.buyer? ? '' : admin_api_logs_path
  end
end