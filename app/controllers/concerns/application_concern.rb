module ApplicationConcern
  extend ActiveSupport::Concern

  def selected_account(klass, receipt)
    account = if (bd = receipt.booking_detail.presence) && (phase = bd.project_unit.try(:phase).presence)
                phase.account
              else
                Phase.where(project_id: receipt.lead.project_id).first.try(:account)
              end

    account.presence || Object.const_get("Account::#{klass.classify}Payment").where(by_default: true).first
  end
end
