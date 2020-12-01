class IncentiveScheme
  include Mongoid::Document
  include Mongoid::Timestamps
  include RangeUtils
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
  validates_uniqueness_of :name
  validates :starts_on, :ends_on, presence: true, unless: :default?
  validates :ladder_strategy, inclusion: { in: STRATEGY }
  validates :ladders, copy_errors_from_child: true
  validates_with IncentiveSchemeValidator

  accepts_nested_attributes_for :ladders, allow_destroy: true
end
