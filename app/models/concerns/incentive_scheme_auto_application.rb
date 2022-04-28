module IncentiveSchemeAutoApplication
  extend ActiveSupport::Concern

  included do
    field :incentive_categories_auto_applied, type: Hash, default: {}
    field :incentive_scheme_data, type: Hash, default: {}
    field :incentive_generated, type: Boolean, default: false

    scope :filter_by_incentive_generated, ->(flag) do
      if flag=="yes"
        where(incentive_generated: true)
      elsif flag=="no"
        where(incentive_generated: false)
      end
    end
  end

  def _tentative_incentive_eligible?
    ::IncentiveScheme::CATEGORIES_PER_RESOURCE[self.class.to_s].any? do |category|
      self.tentative_incentive_eligible?(category)
    end
  end

  def _draft_incentive_eligible?
    ::IncentiveScheme::CATEGORIES_PER_RESOURCE[self.class.to_s].any? do |category|
      self.draft_incentive_eligible?(category)
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
      if self.tentative_incentive_eligible?(category) && self.incentive_categories_auto_applied[category].blank?

        # Maintain incentive categories auto application on resource to avoid calculating same incentive more than once
        icategories_auto_applied = self.incentive_categories_auto_applied.clone
        icategories_auto_applied[category] = 1
        self.set(incentive_categories_auto_applied: icategories_auto_applied)

        # Calculate incentives & generate invoices
        if Rails.env.production? || Rails.env.staging?
          IncentiveCalculatorWorker.perform_async(self.class.to_s, id.to_s, category, timezone: Time.zone.name)
        else
          IncentiveCalculatorWorker.new.perform(self.class.to_s, id.to_s, category)
        end
      end
    end
  end

  # If Incentive Scheme Auto Apply is true only that time invoices will move to draft
  def move_invoices_to_draft
    self.invoices.each do |invoice|
      invoice.change_status("draft") if invoice.invoiceable.draft_incentive_eligible?(invoice.category)
    end
  end

  def move_invoices_to_rejected
    self.invoices.each do |invoice|
      invoice.change_status("reject")
    end
  end

end
