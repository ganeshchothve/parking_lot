class IncentiveSchemeValidator < ActiveModel::Validator
  def validate(is)
    # validate date range
    if is.starts_on.present? && is.ends_on.present?
      is.errors.add :base, 'starts on should be less than ends on date' unless is.starts_on <= is.ends_on
    end

    # validate non overlapping date ranges between all Incentive Schemes present for a project.
    if IncentiveScheme.nin(id: is.id, status: 'disabled')
                      .where(
                        project_id: is.project_id.presence,
                        project_tower_id: is.project_tower_id.presence,
                        tier_id: is.tier_id.presence,
                        category: is.category,
                        brokerage_type: is.brokerage_type,
                      )
                      .lte(starts_on: is.ends_on)
                      .gte(ends_on: is.starts_on).present?

      is.errors.add :base, 'Overlapping date range schemes not allowed under same Project/Tower'
    end

    _ladders = is.ladders.reject(&:marked_for_destruction?)
    is.errors.add :ladders, 'are not present' if _ladders.count < 1
    is.errors.add :ladders, 'cannot be more than 1 in client default incentive scheme' if is.default? && _ladders.count > 1

    if _ladders.present?
      stages = _ladders.map(&:stage)

      # Validate end value of ladders must be present except for last ladder.
      if is.ladders.ne(stage: stages.max).reject(&:marked_for_destruction?).any? {|l| !l.end_value?}
        is.errors.add :base, 'Ladder end value must be present except for last ladder.'
      end

      # Validate last stage ladder to be open ended.
      if _ladders.sort_by{|l| l.stage}.last.try(:end_value).present?
        is.errors.add :base, 'Last ladder should be open ended. Try keeping end value empty.'
      end

      # Validate ladder stage
      stage_missing = (stages.count < stages.max)
      if stage_missing
        missing_stages = ((1..stages.max).to_a - stages)
        is.errors.add :base, "Ladder stage/s #{missing_stages.sort.to_sentence} is/are missing."
      end

      # Validate ladder ranges are not overlapping
      overlap = _ladders.map.with_index do |l, i|
        range_a = l.end_value? ? (l.start_value..l.end_value) : (l.start_value..l.start_value)
        if _l = _ladders[i+1].presence
          range_b = _l.end_value? ? (_l.start_value.._l.end_value) : (_l.start_value.._l.start_value)
          is.ranges_overlap?(range_a, range_b)
        end
      end.any?
      is.errors.add :base, "Overlapping ladder ranges are not allowed." if overlap

      # Validate ladder ranges are continuous
      not_continuous = _ladders.map.with_index do |l, i|
        if (_l = _ladders[i+1].presence) && l.end_value? && (l.end_value < _l.start_value)
          (l.end_value + 1) != _l.start_value
        end
      end.any?
      is.errors.add :base, "Ladder ranges must be continuous" if not_continuous
    end
  end
end
