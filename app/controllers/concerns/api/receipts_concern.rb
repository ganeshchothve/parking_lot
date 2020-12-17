module Api
  module ReceiptsConcern
    extend ActiveSupport::Concern

    def check_any_receipt_params receipt_attributes
      errors = []
      errors << "Receipt with reference id #{receipt_attributes[:reference_id]} is already present" if @lead.receipts.reference_resource_exists?(@crm.id, receipt_attributes[:reference_id].to_s)
      [:issued_date, :processed_on].each do |date_field|
        begin
          Date.strptime( receipt_attributes[date_field], "%d/%m/%Y") if receipt_attributes[date_field].present?
        rescue ArgumentError
          errors << "#{date_field.to_s} date format is invalid. Correct date format is - dd/mm/yyyy"
        end
      end
      errors << "Payment identifier can't be blank" unless receipt_attributes[:payment_identifier].present? || (controller_name == 'receipts' && action_name == 'update')
      errors << "Payment mode can't be blank" unless receipt_attributes[:payment_mode].present? || (controller_name == 'receipts' && action_name == 'update')
      errors << "Status should be clearance_pending or success" if receipt_attributes[:status].present? && %w[clearance_pending success].exclude?( receipt_attributes[:status])
      { "Receipt(#{receipt_attributes[:reference_id]})": errors } if errors.present?
    end

    def modify_any_receipt_params receipt_attributes
      receipt_attributes[:status] = "clearance_pending" unless receipt_attributes[:status].present?
      [:issued_date, :processed_on].each do |date_field|
        receipt_attributes[date_field] = Date.strptime( receipt_attributes[date_field], "%d/%m/%Y") if receipt_attributes[date_field].present?
      end
      # TO - DO Move this to receipt observer
      receipt_attributes[:lead_id] = @lead.id.to_s
      receipt_attributes[:user_id] = @lead.user.id.to_s
      receipt_attributes[:project_id] = @lead.project.id.to_s
      receipt_attributes[:creator_id] = @crm.user_id.to_s
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
