module EmailsHelper
  def custom_emails_path
    current_user.buyer? ? emails_path : admin_emails_path
  end
end
