module InvoicesHelper
  def available_events record
    record.aasm.events(permitted: true).collect{|x| x.name.to_s}
  end

  def filter_incentive_categories
    categories = IncentiveScheme::CATEGORIES
    resultant_categories = []
    if !current_client.enable_leads?
      resultant_categories = categories.reject{|x| x == 'lead'}
    end
    if resultant_categories.present?
      resultant_categories.collect {|x| [t("mongoid.attributes.invoice/categories.#{x}"), x]}
    else
      categories.collect {|x| [t("mongoid.attributes.invoice/categories.#{x}"), x]}
    end
  end
end
