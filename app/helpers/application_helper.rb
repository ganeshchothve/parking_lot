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
end
