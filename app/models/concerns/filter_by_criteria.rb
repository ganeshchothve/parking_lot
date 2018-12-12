module FilterByCriteria

  # to apply all filters, to add new filter only add scope in respective model and filter on frontend, new filter parameter must be inside fltrs hash
  def build_criteria params={}
    params ||= {}
    filters = self.all
    (params[:fltrs] || {}).each do |key, value|
      if self.respond_to?("filter_by_#{key}") && value.present?
        filters = filters.send("filter_by_#{key}", *value)
      end
    end
    filters
  end
end