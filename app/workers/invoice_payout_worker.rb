class InvoicePayoutWorker
  include Sidekiq::Worker

  def perform(invoice_id)
    invoice = Invoice.where(id: invoice_id).first
    if invoice
      crm_base = Crm::Base.where(domain: ENV_CONFIG.dig(:razorpay, :base_url)).first
      if crm_base
        if invoice.brokerage_type == 'sub_brokerage'
          cp_user = case invoice.payment_to
                    when 'channel_partner'
                      invoice.manager
                    when 'company'
                      invoice.channel_partner&.primary_user
                    end
          tpr_id = cp_user&.fund_accounts&.where(account_type: 'vpa', is_active: true)&.first&.crm_reference_id(crm_base) if cp_user

          if tpr_id
            Crm::Api::ExecuteWorker.new.perform('post', 'Invoice', invoice.id.to_s, nil, {'fund_account_id' => tpr_id}, crm_base.id)
          end
        end
      end
    end
  end
end
