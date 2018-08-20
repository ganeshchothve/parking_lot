class ExportMailer < ApplicationMailer
  def notify file_name, to, export_for
    mail.attachments[file_name] = File.read("#{Rails.root}/#{file_name}")
    mail(to: to, cc: User.where(role: "admin").distinct(:email), subject: "Your scheduled export - #{export_for}")
  end
end
