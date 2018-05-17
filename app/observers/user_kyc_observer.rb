class UserKycObserver < Mongoid::Observer
  def after_create user_kyc
    SelldoLeadUpdater.perform_async(user_kyc.user_id)

    mailer = UserKycMailer.send_applicant(user_kyc.id.to_s)
    if Rails.env.development?
      mailer.deliver
    else
      mailer.deliver_later
    end

    mailer = UserKycMailer.send_user(user_kyc.id.to_s)
    if Rails.env.development?
      mailer.deliver
    else
      mailer.deliver_later
    end
  end
end
