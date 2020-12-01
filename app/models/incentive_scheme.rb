class IncentiveScheme
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include IncentiveSchemeStateMachine
  extend FilterByCriteria

  STRATEGY = %w(number_of_items sum_of_value)

  field :name, type: String
  field :starts_on, type: Date
  field :ends_on, type: Date
  field :ladder_strategy, type: String, default: 'number_of_items'
  field :default, type: Boolean, default: false
  field :status, type: String

  belongs_to :booking_portal_client, class_name: 'Client'
  belongs_to :project, optional: -> { !default }
  belongs_to :project_tower, optional: true
  belongs_to :tier, optional: true  # for associating incentive schemes with different channel partner tiers.
  embeds_many :ladders
  has_many :invoices

  delegate :name, to: :project, prefix: true, allow_nil: true

  scope :approved, ->{ where(status: 'approved' )}

  validates :name, :ladder_strategy, presence: true
  validates :starts_on, :ends_on, presence: true, unless: :default?
  validates :ladder_strategy, inclusion: { in: STRATEGY }
  validate :validate_number_of_ladders

  validate do |is|
    # validate date range
    if is.starts_on.present? && is.ends_on.present?
      is.errors.add :base, 'starts on should be less than ends on date' unless is.starts_on <= is.ends_on
    end

    # validate non overlapping date ranges between all Incentive Schemes present for a project.
    if IncentiveScheme.nin(id: is.id, status: 'disabled').where(project_id: is.project_id.presence, project_tower_id: is.project_tower_id.presence, tier_id: is.tier_id.presence)
      .lte(starts_on: is.ends_on)
      .gte(ends_on: is.starts_on).present?

      is.errors.add :base, 'Overlapping date range schemes not allowed under same Project/Tower'
    end

    # Validate last stage ladder to be open ended.
    if is.ladders.any? {|l| l.persisted?}
      if is.ladders.asc(:stage).last.try(:end_value).present?
        is.errors.add :base, 'Last ladder should be open ended. Try keeping end value empty.'
      end

      # Validate ladder stage
      stages = is.ladders.distinct(:stage)
      stage_missing = (stages.count < stages.max)
      if stage_missing
        missing_stages = ((stages.min..stages.max).to_a - stages)
        is.errors.add :base, "Ladder stage/s #{missing_stages.sort.to_sentence} is/are missing."
      end
    end
  end

  accepts_nested_attributes_for :ladders, allow_destroy: true

  def validate_number_of_ladders
    self.errors.add :ladders, 'are not present' if self.ladders.reject(&:marked_for_destruction?).count < 1
    self.errors.add :ladders, 'cannot be more than 1 in client default incentive scheme' if self.default? && self.ladders.reject(&:marked_for_destruction?).count > 1
  end
end
