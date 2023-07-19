class EmailObserver < Mongoid::Observer
  # def before_validation email
  #   email.in_reply_to = "thread-#{email.id}@#{Email.default_email_domain}"
  # end

  def before_create email
    email.to ||= []
    email.cc ||= []
    email.to += email.recipients.distinct(:email).compact.reject{|x| x.blank?}
    email.cc += email.cc_recipients.distinct(:email).compact.reject{|x| x.blank?}
    email.to.compact!
    email.cc.compact!
    email.set_content
  end
end
