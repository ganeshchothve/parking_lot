module EmailConcern
  extend ActiveSupport::Concern
  #
  # This index action for Admin, users where they can view all the emails sent.
  # Admin can  view all the emails and user can view the emails sent to them.
  #
  # @return [{},{}] records with array of Hashes.
  #
  def index
    @emails = Email.build_criteria params
    @emails = @emails.order(created_at: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 15)
  end

  #
  # This show action for Admin, users where they can view the details of a particular email.
  #
  # @return [{}] record with array of Hashes.
  #
  def show; end

  def resend_email
    respond_to do |format|
      if @email.booking_portal_client.email_enabled? && @email.to.present?
        if @email.email_template && @email.email_template.try(:is_active?)
          email_response = Communication::Email::MailgunWorker.new.perform(@email.id.to_s)
          if (email_response.status == 'sent')
            format.html { redirect_to admin_emails_path, notice: t("controller.emails.resend_email.success") }
          else
            format.html { redirect_to admin_emails_path, alert: email_response.response["message"] rescue "Email not sent" }
          end
        else
          format.html { redirect_to admin_emails_path, alert: t("controller.emails.resend_email.emails_template") }
        end
      else
        format.html { redirect_to admin_emails_path, alert: t("controller.emails.resend_email.emails_enabled") }
      end
    end
  end

  private

  def set_email
    @email = Email.where(id: params[:id]).first if params[:id].present?
  end

  def set_layout
    return 'mailer' if action_name == 'show'
    super
  end
end
