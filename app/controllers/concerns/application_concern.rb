module ApplicationConcern
  
  extend ActiveSupport::Concern
  
  def selected_account(project_unit = nil)
    if project_unit.nil?
      Account::RazorpayPayment.where(by_default: true).first
    else
      if project_unit.phase.nil? || project_unit.phase.account.nil?
         Account::RazorpayPayment.where(by_default: true).first
      else
        project_unit.phase.account
      end
    end
  end
end