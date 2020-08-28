module DocumentSignn
  module ZohoSign
    class DocumentCreateWorker
      include Sidekiq::Worker

      def perform(document_sign_id, asset_id, options)
        document_sign = DocumentSign.where(id: document_sign_id).first
        asset = Asset.where(id: asset_id).first
        if asset && document_sign && (["request_name", "recipient_name", "recipient_email"] - options.keys).empty?
          Zoho::Sign.create_and_sign(asset, document_sign, options)
        else
          Rails.logger.error "Required params not sent"
        end
      end
    end
  end
end
