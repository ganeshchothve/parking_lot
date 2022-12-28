module DetailsMaskable
  extend ActiveSupport::Concern

  def masked_email(current_user = nil)
    if maskable_field?(current_user)
      masked_email = ''
      email.chars.each_with_index { |c, i| masked_email << (i.in?([(0..1).to_a, email.index('@'), (email.include?('.') ? email.rindex('.')..email.length : []).to_a].flatten) ? c : '*';) } if email.present?
      masked_email.gsub!(/\*+/, '*****')
    end
    masked_email.presence || email
  rescue StandardError => e
    email
  end

  def masked_phone(current_user = nil)
    if maskable_field?(current_user)
      masked_phone = ''
      if phone.present?
        _phone = phone.gsub(/\s/, '')
        indexes = _phone.include?('+91') ? (0..4).to_a : [0, 1]
        _phone.chars.each_with_index { |c, i| masked_phone << (i.in?(indexes + [_phone.length-2, _phone.length-1]) ? c : '*') }
      end
      masked_phone
    end
    masked_phone.presence || phone
  end

  def maskable_field?(current_user = nil)
    current_user && current_user.in_masked_details_user_group? && (self.is_a?(UserKyc) || (self.buyer? && current_user != self))
  end

end
