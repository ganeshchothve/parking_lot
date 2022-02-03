class ExpireRegisterPartnerInExistingCompanyLinkWorker
  include Sidekiq::Worker

  def perform user_id
    user = User.where(id: user_id).first
    if user
      # Expire the register link sent to company owner after 24 hrs, so that the channel partner can register in existing company again.
      user.update(register_in_cp_company_token: nil, event: 'inactive') if user.aasm(:company).current_state == :pending_approval
    end
  end
end
