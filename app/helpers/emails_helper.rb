module EmailsHelper
  def custom_emails_path
    current_user.buyer? ? buyer_emails_path : admin_emails_path
  end
end
