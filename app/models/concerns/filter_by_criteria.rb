module FilterByCriteria

  # to apply all filters, to add new filter only add scope in respective model and filter on frontend, new filter parameter must be inside fltrs hash
  def build_criteria params={}
    params ||= {}
    filters = self.all
    if params.is_a?(Hash)
      filter_parameters = ActionController::Parameters.new(params[:fltrs] || {}).try(:permit!)
    else
      filter_parameters = params[:fltrs].try(:permit!)
    end
    (filter_parameters&.to_h || {}).each do |key, value|
      if value.present? && self.respond_to?("filter_by_#{key}")
        filters = filters.send("filter_by_#{key}", (value == 'nil' ? nil : value))
      end
    end
    filters = filters.filter_by_search(params[:search]) if params[:search].present? && self.respond_to?('filter_by_search')
    field_name, sort_order = params.dig(:fltrs, :sort).to_s.split(".")
    filters = filters.order_by([ (field_name || :created_at), (sort_order || :desc) ])
    filters
  end
end
