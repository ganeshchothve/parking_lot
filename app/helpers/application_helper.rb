module ApplicationHelper
  def global_labels
    t('global').with_indifferent_access
  end

  def global_label(key, params={})
    t("global.#{key}", params)
  end

  def number_to_indian_currency(number)
    if number
      string = number.to_s.split('.')
      number = string[0].gsub(/(\d+)(\d{3})$/){ p = $2;"#{$1.reverse.gsub(/(\d{2})/,'\1,').reverse},#{p}"}
      number = number.gsub(/^,/, '')
      number = number + '.' + string[1] if string[1].to_f > 0
    end
    "&#8377;#{number}".html_safe
  end

  def float_to_int (x)
    Float(x)
    i, f = x.to_i, x.to_f
    i == f ? i : f
  rescue ArgumentError
    x
  end

  def calculate_percent(amount, percent)
    amount = amount * percent/100
    amount.round
  end

  def current_client
    return @current_client if @current_client.present?
    if defined?(request) && request && request.subdomain.present? && request.domain.present?
      domain = (request.subdomain.present? ? "#{request.subdomain}." : "") + "#{request.domain}"
      @current_client = Client.in(booking_portal_domains: domain).first
    else
      @current_client = Client.first # GENERICTODO: handle this
    end
  end

  def current_project
    return @current_project if @current_project.present?
    # TODO: for now we are considering one project per client only so loading first client project here
    @current_project = current_client.projects.first if current_client.present?
  end
end
