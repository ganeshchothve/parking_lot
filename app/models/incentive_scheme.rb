class IncentiveScheme
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  extend FilterByCriteria

  STRATEGY = %w(number_of_items sum_of_value)

  field :name, type: String
  field :starts_on, type: Date
  field :ends_on, type: Date
  field :ladder_strategy, type: String, default: 'number_of_items'
  field :default, type: Boolean, default: false

  belongs_to :booking_portal_client, class_name: 'Client'
  belongs_to :project, optional: -> { !default }
  belongs_to :project_tower, optional: true
  embeds_many :ladders

  delegate :name, to: :project, prefix: true, allow_nil: true

  validates :name, :ladder_strategy, presence: true
  validates :starts_on, :ends_on, presence: true, unless: :default?
  validates :ladder_strategy, inclusion: { in: STRATEGY }
  validates :ladders, length: {minimum: 1, message: 'are not present'}
  validate do |is|
    # validate date range
    if is.starts_on.present? && is.ends_on.present?
      is.errors.add :base, 'starts on should be less than ends on date' unless is.starts_on < is.ends_on
    end

    # validate non overlapping date ranges between all Incentive Schemes present for a project.
    if IncentiveScheme.nin(id: is.id).where(project_id: is.project_id.presence, project_tower_id: is.project_tower_id.presence)
      .lte(starts_on: is.ends_on)
      .gte(ends_on: is.starts_on).present?

      is.errors.add :base, 'Overlapping date range schemes not allowed under same Project/Tower'
    end

    # Validate last stage ladder to be open ended.
    if is.ladders?
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

end
