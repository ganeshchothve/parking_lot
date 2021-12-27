module IncentiveSchemeAutoApplication
  extend ActiveSupport::Concern

  included do
    field :incentive_scheme_data, type: Hash, default: {}

    scope :not_eligible, -> { where(non_existent_attribute: 'present') }
  end

  def _incentive_eligible?
    ::IncentiveScheme::CATEGORIES_PER_RESOURCE[self.class.to_s].any? do |category|
      self.incentive_eligible?(category)
    end
  end

  def invoiceable_price
  end

  # Find incentive schemes
  def find_incentive_schemes(category)
    tier_id = manager&.tier_id
    incentive_schemes = ::IncentiveScheme.approved.where(resource_class: self.class.to_s, category: category, project_id: project_id, auto_apply: true).lte(starts_on: invoiceable_date).gte(ends_on: invoiceable_date)
    # Find tier level scheme
    if tier_id
      incentive_schemes = incentive_schemes.where(tier_id: tier_id)
    end
    incentive_schemes
  end

  # Find all the resources for a channel partner that fall under this scheme
  def find_all_resources_for_scheme(i_scheme)
    resources = self.class.incentive_eligible(i_scheme.category).where(project_id: i_scheme.project_id, :"incentive_scheme_data.#{i_scheme.id.to_s}".exists => true, manager_id: self.manager_id).gte(scheduled_on: i_scheme.starts_on).lte(scheduled_on: i_scheme.ends_on)
    self.class.or(resources.selector, {id: self.id})
  end

  def calculate_incentive
    ::IncentiveScheme::CATEGORIES_PER_RESOURCE[self.class.to_s].each do |category|
      if self.incentive_eligible?(category)
        # Calculate incentives & generate invoices
        if Rails.env.production? || Rails.env.staging?
          IncentiveCalculatorWorker.perform_async(self.class.to_s, id.to_s, category)
        else
          IncentiveCalculatorWorker.new.perform(self.class.to_s, id.to_s, category)
        end
      end
    end
  end
end
