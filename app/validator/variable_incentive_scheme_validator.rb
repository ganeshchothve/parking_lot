class VariableIncentiveSchemeValidator < ActiveModel::Validator
  def validate(vis)
    # validate date range
    if vis.start_date.present? && vis.end_date.present?
      vis.errors.add :base, 'start date should be less than end date' unless vis.start_date <= vis.end_date
    end

    existing_variable_schemes = VariableIncentiveScheme.nin(id: vis.id, status: 'disabled').in(project_ids: vis.project_ids).lte(start_date: vis.end_date).gte(end_date: vis.start_date).approved.present?
    if existing_variable_schemes.present?
      vis.errors.add :base, 'selected projects should not be present in other Variable Incentive Schemes'
    end
  end
end