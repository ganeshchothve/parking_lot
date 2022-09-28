class Admin::DocumentSignController < AdminController
  # before_action :authorize_resource
  layout false

  def prompt
    redirect_to current_client.document_sign.authorization_url
  end

  def callback
    begin
      current_client.document_sign.authorize_first_token!(params[:code])
      flash = I18n.t("controller.document_signs.notice.connected", name: "#{current_client.document_sign.vendor_class}")
    rescue StandardError => e
      flash = I18n.t("controller.document_signs.errors.could_not_connect", name: "#{current_client.document_sign.vendor_class}")
    end
    redirect_to home_path(current_user), notice: flash
  end
end
