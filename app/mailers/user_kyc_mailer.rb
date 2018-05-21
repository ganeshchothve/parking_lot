class UserKycMailer < ApplicationMailer
  def send_applicant user_kyc_id
    @user_kyc = UserKyc.find(user_kyc_id)
    @user = @user_kyc.user
    mail(to: @user_kyc.email, subject: "User KYC added on Embassy")
  end

  def send_user user_kyc_id
    @user_kyc = UserKyc.find(user_kyc_id)
    @user = @user_kyc.user
    mail(to: @user.email, subject: "User KYC added on Embassy")
  end
end
