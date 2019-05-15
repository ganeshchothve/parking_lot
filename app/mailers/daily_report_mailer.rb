class DailyReportMailer < ApplicationMailer
  def payments_report file_name, count
    @count = count
    mail.attachments[file_name] = File.read("#{Rails.root}/exports/#{file_name}")
    make_bootstrap_mail(to: User.where(role: "admin").distinct(:email), subject: "Daily Payments Report - #{Date.current}")
  end
end
