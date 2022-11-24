class ExportMailer < ApplicationMailer
  def notify file_name, to, export_for, user_id=nil
    user = User.where(id: user_id).first
    booking_portal_client_id = user.try(:booking_portal_client).try(:id)
    mail.attachments[file_name] = File.read("#{Rails.root}/exports/#{file_name}")
    make_bootstrap_mail(to: to, cc: User.where(booking_portal_client_id: booking_portal_client_id, role: "admin").distinct(:email), subject: "Your scheduled export - #{export_for}")
  end
end
