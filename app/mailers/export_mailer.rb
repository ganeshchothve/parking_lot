class ExportMailer < ApplicationMailer
  def notify file_name, to, export_for, user_id=nil
    user = User.where(id: user_id).first
    booking_portal_client = user.booking_portal_client
    mail.attachments[file_name] = File.read("#{Rails.root}/exports/#{file_name}")
    make_bootstrap_mail(from: booking_portal_client.sender_email, to: to, cc: User.where(booking_portal_client_id: booking_portal_client.id, role: "admin").distinct(:email), subject: "Your scheduled export - #{export_for}")
  end
end
