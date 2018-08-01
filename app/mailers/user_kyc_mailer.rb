class UserKycMailer < ApplicationMailer
  def send_applicant user_kyc_id
    @user_kyc = UserKyc.find(user_kyc_id)
    @user = @user_kyc.user
    # make_bootstrap_mail(to: @user_kyc.email, subject: "User KYC added on " + current_client.name)
  end

  def send_user user_kyc_id
    @user_kyc = UserKyc.find(user_kyc_id)
    @user = @user_kyc.user
    # make_bootstrap_mail(to: @user.email, subject: "User KYC added on " + current_client.name)
  end
end
