class VariableIncentiveSchemeValidator < ActiveModel::Validator
  def validate(vis)
    # validate date range
    if vis.start_date.present? && vis.end_date.present?
      vis.errors.add :base, 'start date should be less than end date' unless vis.start_date <= vis.end_date
    end
  end
end