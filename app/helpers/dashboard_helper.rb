module DashboardHelper
  def custom_sales_board_path
    current_user.buyer? ? '' : sales_board_path
  end

  #
  # Convert formula to readable string
  # 0.02 * self.calculate_agreement_price => 2% of Agreement value
  #
  def formula_to_human(formula)
    percentage = formula.scan(/\d+[,.]\d+/)[0]

    #value_of = formula.scan(/agreement_price|all_inclusive_price/)
    #result = [percentage, value_of].flatten.map
      #.with_index { |x, i| i.zero? ? "<strong>#{number_to_percentage((_x = x.to_f * 100), precision: (_x == _x.to_i ? 0 : 2))}</strong>" : t("formula.#{x}") }.join(' of ').html_safe
    #result.presence || formula
    number_to_percentage((percentage = percentage.to_f * 100), precision: (percentage == percentage.to_i ? 0 : 2))
  end
end
