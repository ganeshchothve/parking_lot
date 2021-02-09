module DashboardHelper
  #
  # Convert formula to readable string
  # 0.02 * self.calculate_agreement_price => 2% of Agreement value
  #
  def formula_to_human(formula)
    result = formula.scan(/(\d*\.\d+)\s*\*\s*[self\.]*(.*[agreement_price|all_inclusive_price])/)
      .flatten
      .map
      .with_index { |x, i| i.zero? ? "<strong>#{number_to_percentage((_x = x.to_f * 100), precision: (_x == _x.to_i ? 0 : 2))}</strong>" : t("formula.#{x}") }.join(' of ').html_safe
    result.presence || formula
  end
end
