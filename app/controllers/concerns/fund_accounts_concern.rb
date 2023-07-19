module FundAccountsConcern
  extend ActiveSupport::Concern

  private

  def push_fund_account_on_create_or_change(format, user)
    if user.role.in?(%w(cp_owner channel_partner))
      # Create/Update fund account if found in params
      if user.fund_accounts.blank?
        if params.dig(:user, :fund_accounts, :address).present?
          fund_account = user.fund_accounts.build(booking_portal_client_id: current_client.id)
          fund_account.assign_attributes(params.dig(:user, :fund_accounts).permit(FundAccountPolicy.new(current_user, fund_account).permitted_attributes))
        end
      else
        fund_account = user.fund_accounts.first
        if params.dig(:user, :fund_accounts).present?
          fund_account.assign_attributes(params.dig(:user, :fund_accounts).permit(FundAccountPolicy.new(current_user, fund_account).permitted_attributes))
        end
      end

      # Create/Update fund account in razorpay if its api is configured
      razorpay_base = Crm::Base.where(booking_portal_client_id: current_client.try(:id), domain: ENV_CONFIG.dig(:razorpay, :base_url)).first
      if fund_account && razorpay_base
        if fund_account.new_record?
          razorpay_api, api_log = fund_account.push_in_crm(razorpay_base) if fund_account.is_active?

        elsif fund_account.is_active_changed?
          razorpay_fund_id = fund_account.crm_reference_id(razorpay_base)

          if fund_account.is_active? && razorpay_fund_id.present? && (fund_account.address_changed? || fund_account.address != fund_account.old_address)
            razorpay_api, api_log = fund_account.push_in_crm(razorpay_base, true)
            # In case of user updates to old inactive fund account,
            # Call razorpay api again to activate it. As above api call will create the fund account, but as its already present on razorpay in inactive form, it will just return its id & won't update its activeness.
            razorpay_api, api_log = fund_account.push_in_crm(razorpay_base) if api_log.present? && api_log.status == 'Success'
          else
            razorpay_api, api_log = fund_account.push_in_crm(razorpay_base)
            if razorpay_api.blank? || (api_log.present? && api_log.status == 'Success')
              fund_account.old_address = fund_account.address
            end
          end
        end
      end
    end

    if razorpay_api.blank? || api_log.blank? || api_log.status == 'Success'
      if fund_account.blank? || fund_account.save
        yield
      else
        format.json { render json: {errors: fund_account.errors.full_messages}, status: :unprocessable_entity }
      end
    else
      format.json { render json: {errors: api_log.message}, status: :unprocessable_entity }
    end
  end

end
