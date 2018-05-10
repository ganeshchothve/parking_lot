class UserKycObserver < Mongoid::Observer
  def after_create user_kyc
    mailer = UserKycMailer.send_applicant(user_request.id.to_s)
    if Rails.env.development?
      mailer.deliver
    else
      mailer.deliver_later
    end

    mailer = UserKycMailer.send_user(user_request.id.to_s)
    if Rails.env.development?
      mailer.deliver
    else
      mailer.deliver_later
    end
  end
end
