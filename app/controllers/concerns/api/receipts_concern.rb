module Api
  module ReceiptsConcern
    extend ActiveSupport::Concern

    def check_any_receipt_params receipt_attributes
      errors = []
      errors << I18n.t("controller.receipts.errors.receipt_reference_id_already_exists", name: "#{receipt_attributes[:reference_id]}") if @lead.receipts.reference_resource_exists?(@crm.id, receipt_attributes[:reference_id].to_s)
      [:issued_date, :processed_on].each do |date_field|
        begin
          Date.strptime( receipt_attributes[date_field], "%d/%m/%Y") if receipt_attributes[date_field].present?
        rescue ArgumentError
          errors << I18n.t("global.errors.invalid_date_format", name: "#{date_field.to_s}")
        end
      end
      errors << I18n.t("controller.receipts.errors.payment_identifier.blank") unless receipt_attributes[:payment_identifier].present? || (controller_name == 'receipts' && action_name == 'update')
      errors << I18n.t("controller.receipts.errors.status_should_present") unless receipt_attributes[:status].present?
      errors << I18n.t("controller.receipts.errors.status_should_success") if receipt_attributes[:status].present? && %w[clearance_pending success].exclude?( receipt_attributes[:status])
      { "Receipt(#{receipt_attributes[:reference_id]})": errors } if errors.present?
    end

    def modify_any_receipt_params receipt_attributes
      [:issued_date, :processed_on].each do |date_field|
        receipt_attributes[date_field] = Date.strptime( receipt_attributes[date_field], "%d/%m/%Y") if receipt_attributes[date_field].present?
      end
      # TO - DO Move this to receipt observer
      receipt_attributes[:lead_id] = @lead.id.to_s
      receipt_attributes[:user_id] = @lead.user.id.to_s
      receipt_attributes[:project_id] = @lead.project.id.to_s
      receipt_attributes[:creator_id] = @crm.user_id.to_s
      receipt_attributes[:payment_mode] = "cheque" if receipt_attributes[:payment_mode].blank?
      # add third party references
      if receipt_reference_id = receipt_attributes.dig(:reference_id).presence
        tpr_attrs = {
          crm_id: @crm.id.to_s,
          reference_id: receipt_reference_id
        }
        if @receipt
          tpr = @receipt.third_party_references.where(reference_id: params[:id], crm_id: @crm.id).first
          tpr_attrs[:id] = tpr.id.to_s if tpr
        end
        receipt_attributes[:third_party_references_attributes] = [ tpr_attrs ]
      end
      receipt_attributes
    end
  end
end
