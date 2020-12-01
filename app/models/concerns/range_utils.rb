module RangeUtils
  extend ActiveSupport::Concern
  def ranges_overlap?(range_a, range_b)
    range_b.begin <= range_a.end && range_a.begin <= range_b.end
  end
end
