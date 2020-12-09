class DailyReportMailer < ApplicationMailer
  def payments_report file_name, count, project_id
    @project = Project.where(id: project_id).first
    @count = count
    mail.attachments[file_name] = File.read("#{Rails.root}/exports/#{file_name}")
    make_bootstrap_mail(to: current_client.notification_email.split(',').map(&:strip).uniq.compact, subject: "#{@project.name} - Daily Payments Report - #{Date.current}")
  end
end
