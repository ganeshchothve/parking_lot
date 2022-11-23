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

  def filter_incentive_scheme_resources client
    incentive_scheme_resources = IncentiveScheme::RESOURCE_CLASS
    resultant_resources = []
    resultant_resources = if !client.enable_leads && client.enable_site_visit
      incentive_scheme_resources.reject{|doc| %w(Lead).include?(doc)}
    elsif client.enable_leads && !client.enable_site_visit
      incentive_scheme_resources.reject{|doc| %w(SiteVisit).include?(doc)}
    elsif !client.enable_leads && !client.enable_site_visit
      incentive_scheme_resources.reject{|doc| %w(SiteVisit Lead).include?(doc)}
    else
      incentive_scheme_resources
    end
    options = resultant_resources.collect{|x| [t("mongoid.attributes.incentive_scheme/resource_class.#{x}"), x]}
    options
  end

  def incentive_scheme_tooltip(scheme)
    html_content = "<table class='table-bordered'><tbody>"
    scheme.ladders.asc(:stage).each do |ladder|
      html_content += "<tr>"

      # First column
      html_content += "<td class='p-3'>Ladder <strong>##{ladder.stage}</strong></td>"

      # Second column
      if scheme.ladder_strategy == 'number_of_items'
        html_content += "<td class='p-3'>"
        if ladder.end_value?
          html_content += "<strong>#{ladder.start_value}</strong> - <strong>#{ladder.end_value}</strong> #{BookingDetail.model_name.human(count: 2)}"
        else
          html_content += "<strong>#{ladder.start_value.ordinalize}</strong> #{BookingDetail.model_name.human} onwards"
        end
      elsif scheme.ladder_strategy == 'sum_of_value'
        html_content += "<td class='p-3'>"
        if ladder.end_value?
          html_content += "<strong>#{number_to_indian_currency(ladder.start_value, :indian)}</strong> - <strong>#{number_to_indian_currency(ladder.end_value, :indian)}</strong> #{t('global.agreement_value')}"
        else
          html_content += "<strong>#{number_to_indian_currency(ladder.start_value, :indian)}</strong> #{t('global.agreement_value')} onwards"
        end
      end
      html_content += "</td>"

      # Third column
      adj = ladder.payment_adjustment
      html_content += "<td class='p-3'>"
      if adj.absolute_value.blank? && adj.formula.present?
        html_content += "#{formula_to_human(adj.formula)}</td>"
      else
        html_content += "<strong>#{number_to_indian_currency(adj.absolute_value)}</strong></td>"
      end

      html_content += "</tr>"
    end
    html_content += "</tbody></table>"
    html_content
  end

end
