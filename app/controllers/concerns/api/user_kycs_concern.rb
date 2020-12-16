module Api
  module UserKycsConcern
    extend ActiveSupport::Concern

    def check_any_user_kyc_params kyc_attributes
      return if kyc_attributes.blank?
      errors = []
      errors << "User Kyc with reference id #{kyc_attributes[:reference_id]} is already present" if @lead.user_kycs.reference_resource_exists?(@crm.id, kyc_attributes[:reference_id].to_s)
      [:dob, :anniversary].each do |date_field|
        begin
          Date.strptime( kyc_attributes[date_field], "%d/%m/%Y") if kyc_attributes[date_field].present?
        rescue ArgumentError
          errors << "#{date_field.to_s} date format is invalid. Correct date format is - dd/mm/yyyy"
        end
      end
      [:nri, :poa, :is_company, :existing_customer].each do |boolean_field|
        errors << "#{boolean_field} should be a boolean value - true or false" if kyc_attributes[boolean_field].present? && !kyc_attributes[boolean_field].is_a?(Boolean)
      end
      [:number_of_units, :budget].each do |integer_field|
        errors << "#{integer_field} should be a boolean value - true or false" if kyc_attributes[integer_field].present? && !kyc_attributes[integer_field].is_a?(Integer)
      end
      { "UserKyc(#{kyc_attributes[:reference_id]})": errors } if errors.present?
    end

    def modify_any_user_kyc_params kyc_attributes
      return if kyc_attributes.blank?
      [:dob, :anniversary].each do |date_field|
        kyc_attributes[date_field] = Date.strptime( kyc_attributes[date_field], "%d/%m/%Y") if kyc_attributes[date_field].present?
      end
      kyc_attributes[:lead_id] = @lead.id.to_s
      kyc_attributes[:user_id] = @lead.user.id.to_s
      if kyc_reference_id = kyc_attributes.dig(:reference_id).presence
      # add third party references
        tpr_attrs = {
          crm_id: @crm.id.to_s,
          reference_id: kyc_reference_id
        }
        if @user_kyc
          tpr = @user_kyc.third_party_references.where(reference_id: params[:id], crm_id: @crm.id).first
          tpr_attrs[:id] = tpr.id.to_s if tpr
        end
        kyc_attributes[:third_party_references_attributes] = [ tpr_attrs ]
        kyc_attributes[:creator_id] = @crm.user_id.to_s
      end
      if @user_kyc
        kyc_attributes[:addresses_attributes].each_with_index do |addr_attrs, i|
        addr = @user_kyc.addresses.where(address_type: addr_attrs[:address_type]).first
        kyc_attributes[:addresses_attributes][i][:id] = addr.id.to_s if addr.present?
      end
    end
      kyc_attributes
    end
  end
end
