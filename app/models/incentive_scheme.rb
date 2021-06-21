class IncentiveScheme
  include Mongoid::Document
  include Mongoid::Timestamps
  include RangeUtils
  include ArrayBlankRejectable
  include InsertionStringMethods
  include IncentiveSchemeStateMachine
  extend FilterByCriteria

  STRATEGY = %w(number_of_items sum_of_value)
  DOCUMENT_TYPES = []
  CATEGORIES = %w( hot normal )

  field :name, type: String
  field :description, type: String
  field :category, type: String
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
  has_many :booking_details
  has_many :assets, as: :assetable

  delegate :name, to: :project, prefix: true, allow_nil: true

  scope :filter_by_name, ->(name) { where(name: ::Regexp.new(::Regexp.escape(name), 'i')) }
  scope :filter_by_search, ->(search) { where(name: ::Regexp.new(::Regexp.escape(search), 'i')) }
  scope :filter_by_status, ->(status) { where(status: status) }
  scope :filter_by_project_id, ->(project_id) { where(project_id: project_id) }
  scope :filter_by_project_ids, ->(project_ids){ project_ids.present? ? where(project_id: {"$in": project_ids}) : all }
  scope :filter_by_project_tower_id, ->(project_tower_id) { where(project_tower_id: project_tower_id) }
  scope :filter_by_tier_id, ->(tier_id) { where(tier_id: tier_id) }
  scope :filter_by_ladder_strategy, ->(ladder_strategy) { where(ladder_strategy: ladder_strategy) }
  scope :filter_by_date_range, ->(date) {start_date, end_date = date.split(' - '); where(starts_on: {'$lte': end_date}, ends_on: {'$gte': start_date})}

  validates :name, :category, :description, :ladder_strategy, presence: true
  validates_uniqueness_of :name
  validates :starts_on, :ends_on, presence: true, unless: :default?
  validates :ladder_strategy, inclusion: { in: STRATEGY }
  validates :ladders, copy_errors_from_child: true
  validates_with IncentiveSchemeValidator

  accepts_nested_attributes_for :ladders, allow_destroy: true
end
