class SendInvoiceToPocMailer < ApplicationMailer
  def notify invoice, to
    mail.attachments['Invoice'] = File.read(invoice.assets.where(asset_type: 'system_generated_invoice').first.file.file.file)
    make_bootstrap_mail(to: to, subject: "Invoice raise for booking - #{invoice.booking_detail.id}")
  end
end
