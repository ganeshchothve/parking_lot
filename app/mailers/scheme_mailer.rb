class SchemeMailer < ApplicationMailer

  def send_draft scheme_id
    @scheme = Scheme.find(scheme_id)
    make_bootstrap_mail(to: @scheme.created_by.email, subject: "Scheme #{@scheme.name} Requested")
  end

  def send_approved scheme_id
    @scheme = Scheme.find(scheme_id)
    make_bootstrap_mail(to: @scheme.created_by.email, cc: @scheme.approved_by.email, subject: "Scheme #{@scheme.name} Approved")
  end

  def send_disabled scheme_id
    @scheme = Scheme.find(scheme_id)
    make_bootstrap_mail(to: @scheme.created_by.email, cc: (@scheme.approved_by.email rescue []), subject: "Scheme #{@scheme.name} Disabled")
  end
end
