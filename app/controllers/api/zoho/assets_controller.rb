class Api::Zoho::AssetsController < ApplicationController

  skip_before_action :verify_authenticity_token

  def download
    document_sign_detail = DocumentSignDetail.where(document_id: params.dig("requests", "document_ids", 0, "document_id")).first
    document_sign = document_sign_detail.booking_portal_client.document_sign
    response = Zoho::Sign.download document_sign, document_sign_detail
    respond_to do |format|
      format.json{ render json: response }
    end
  end
end