class ApplicationMailer < ActionMailer::Base
  helper ApplicationHelper
  include ApplicationHelper
  extend ApplicationHelper

  # if current_client
  #   # default from: "#{current_client.name} <#{current_client.sender_email}>", cc: "#{current_client.notification_email}"
  # else
    default from: "Sell.Do <support@sell.do>"
  # end
  layout 'mailer'

  def test params
    body = params.delete :body
    if params[:attachment_urls].present?
      params[:attachment_urls].each do |attach|
        attach = (attach.is_a?(File) ? attach : File.read("#{Rails.root}/public/#{attach}"))
        attachments[File.basename(attach.path)] = attach.read
      end
    end
    bootstrap = BootstrapEmail::Compiler.new(
      mail(params) do |format|
        format.html{ render(layout: "layouts/mailer.html.erb", body: body) }
      end
    )
    bootstrap.perform_full_compile
    bootstrap
  end
end
