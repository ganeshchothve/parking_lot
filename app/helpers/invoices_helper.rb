module InvoicesHelper
  def custom_invoices_path
    admin_invoices_path
  end

  def available_events record
    record.aasm.events(permitted: true).collect{|x| x.name.to_s}
  end

  def filter_incentive_categories client
    categories = IncentiveScheme::CATEGORIES
    resultant_categories = []
    resultant_categories = if client.enable_site_visit? && !client.enable_leads?
      categories.reject{|x| x == 'lead'}
    elsif !client.enable_site_visit? && client.enable_leads?
      categories.reject{|x| x == 'walk_in'}
    elsif !client.enable_site_visit? && !client.enable_leads?
      categories.reject{|x| %(lead walk_in).include?(x)}
    else
      categories
    end
    resultant_categories = resultant_categories.collect {|x| [t("mongoid.attributes.invoice/categories.#{x}"), x]}
    resultant_categories
  end
end
