module IncentiveSchemesHelper
  def custom_incentive_schemes_path
    admin_incentive_schemes_path
  end

  def available_statuses incentive_scheme
    if incentive_scheme.new_record?
      [ 'draft' ]
    else
      statuses = incentive_scheme.aasm.events(permitted: true).collect{|x| x.name.to_s}
    end
  end

  def incentive_scheme_tooltip(scheme)
    html_content = ""
    scheme.ladders.asc(:stage).each do |ladder|
      html_content += "<span class='list-group-item align-items-start'>
                        <div class='d-flex w-100 justify-content-between'>
                          <h5 class='mb-1'>Ladder ##{ladder.stage}</h5>"
      adj = ladder.payment_adjustment
      html_content += "<p class='mb-1'>"
      if adj.absolute_value.blank? && adj.formula.present?
        html_content += "#{formula_to_human(adj.formula)}"
      else
        html_content += "<strong>#{number_to_indian_currency(adj.absolute_value)}</strong>"
      end
        if scheme.ladder_strategy == 'number_of_items'
          html_content += "<p>"
          if ladder.end_value?
            html_content += "<strong>#{ladder.start_value}</strong> - <strong>#{ladder.end_value}</strong> #{BookingDetail.model_name.human(count: 2)}"
          else
            html_content += "<strong>#{ladder.start_value.ordinalize}</strong> #{BookingDetail.model_name.human} onwards"
          end
          html_content += "</p>"
        elsif scheme.ladder_strategy == 'sum_of_value'
          html_content += "<p>"
          if ladder.end_value?
            html_content += "<strong>#{number_to_indian_currency(ladder.start_value, :indian)}</strong> - <strong>#{number_to_indian_currency(ladder.end_value, :indian)}</strong> #{t('global.agreement_value')}"
          else
            html_content += "<strong>#{number_to_indian_currency(ladder.start_value, :indian)}</strong> #{t('global.agreement_value')} onwards"
          end
          html_content += "</p>"
        end
      html_content += "</span>"
    end
    html_content
  end

end
