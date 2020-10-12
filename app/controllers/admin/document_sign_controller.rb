class Admin::DocumentSignController < AdminController
  # before_action :authorize_resource
  layout false

  def prompt
    redirect_to current_client.document_sign.authorization_url
  end

  def callback
    begin
      current_client.document_sign.authorize_first_token!(params[:code])
      flash = "Connected your #{current_client.document_sign.vendor_class} Account successfully"
    rescue StandardError => e
      flash = "Couldn't connect with your #{current_client.document_sign.vendor_class} Account"
    end
    redirect_to home_path(current_user, notice: flash)
  end
end
