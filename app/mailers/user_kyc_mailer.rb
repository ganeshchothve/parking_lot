class UserKycMailer < ApplicationMailer
  def send_applicant user_kyc_id
    @user_kyc = UserKyc.find(user_kyc_id)
    @user = @user_kyc.user
    @client = Client.where(id: RequestStore::Base.get("client_id")).first
    mail(to: @user_kyc.email, subject: "User KYC added on " + @client.name)
  end

  def send_user user_kyc_id
    @user_kyc = UserKyc.find(user_kyc_id)
    @user = @user_kyc.user
    @client = @user.booking_portal_client
    mail(to: @user.email, subject: "User KYC added on " + @client.name)
  end
end
