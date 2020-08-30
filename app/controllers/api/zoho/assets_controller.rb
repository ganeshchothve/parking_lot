class Api::Zoho::AssetsController < ApplicationController

  def download
    document_sign_detail = DocumentSignDetail.where(document_id: params[:document_id], request_id: params[:request_id]).first
    document_sign = Client.first.document_sign
    Zoho::Sign.download document_sign, document_sign_detail
  end
end