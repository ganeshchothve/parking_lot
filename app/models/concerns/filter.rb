module Filter
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    # to apply all filters, to add new filter only add scope in respective model and filter on frontend, new filter parameter must be inside fltrs hash
    def build_criteria params = {}
      filters = all
      if params[:fltrs]
        params[:fltrs].each do |key, value|
          filters = filters.send("filter_by_#{key}", *value) if respond_to?("filter_by_#{key}") && value.present?
        end
      end
      filters
    end
  end
end
