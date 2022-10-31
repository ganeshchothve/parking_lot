module InvoicesHelper
  def available_events record
    record.aasm.events(permitted: true).collect{|x| x.name.to_s}
  end

  def filter_incentive_categories
    categories = IncentiveScheme::CATEGORIES
    resultant_categories = []
    resultant_categories = if current_client.enable_site_visit? && !current_client.enable_leads?
      categories.reject{|x| x == 'lead'}
    elsif !current_client.enable_site_visit? && current_client.enable_leads?
      categories.reject{|x| x == 'walk_in'}
    elsif !current_client.enable_site_visit? && !current_client.enable_leads?
      categories.reject{|x| %(lead walk_in).include?(x)}
    else
      categories
    end
    resultant_categories = resultant_categories.collect {|x| [t("mongoid.attributes.invoice/categories.#{x}"), x]}
    resultant_categories
  end
end
