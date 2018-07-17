class MisReportMailer < ApplicationMailer
  def notify file_name, to, mis_report_for
    mail.attachments[file_name] = File.read("#{Rails.root}/#{file_name}")
    mail(to: to, subject: "Your scheduled MIS-report - #{mis_report_for}")
  end
end
