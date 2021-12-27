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
  CATEGORIES = %w(walk_in spot_booking lead referral brokerage)
  RESOURCE_CLASS = %w[SiteVisit Lead BookingDetail User]
  BROKERAGE_TYPE = %w[brokerage sub_brokerage]
  PAYMENT_TO = %w[company channel_partner]
  CATEGORIES_PER_RESOURCE = {
    'SiteVisit' => %w[walk_in],
    'Lead' => %w[lead],
    'BookingDetail' => %w[spot_booking brokerage],
    'User' => %w[referral]
  }

  field :name, type: String
  field :description, type: String
  field :starts_on, type: Date
  field :ends_on, type: Date
  field :ladder_strategy, type: String, default: 'number_of_items'
  field :default, type: Boolean, default: false
  field :status, type: String
  field :resource_class, type: String, default: 'BookingDetail'
  field :category, type: String
  field :brokerage_type, type: String, default: 'sub_brokerage'
  field :payment_to, type: String, default: 'company'
  field :auto_apply, type: String, default: true

  belongs_to :booking_portal_client, class_name: 'Client'
  belongs_to :project, optional: -> { !default || resource_class == 'User' }
  belongs_to :project_tower, optional: true
  belongs_to :tier, optional: true  # for associating incentive schemes with different channel partner tiers.
  embeds_many :ladders
  has_many :invoices
  #has_many :booking_details
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
  scope :filter_by_category, ->(category) { where(category: category) }
  scope :filter_by_brokerage_type, ->(brokerage_type) { where(brokerage_type: brokerage_type) }
  scope :filter_by_payment_to, ->(payment_to) { where(payment_to: payment_to) }
  scope :filter_by_resource_class, ->(resource_class) { where(resource_class: resource_class) }
  scope :filter_by_date_range, ->(date) {start_date, end_date = date.split(' - '); where(starts_on: {'$lte': end_date}, ends_on: {'$gte': start_date})}

  validates :name, :category, :description, :brokerage_type, :payment_to, :ladder_strategy, presence: true
  #validates_uniqueness_of :name
  validates :starts_on, :ends_on, presence: true, unless: :default?
  validates :ladder_strategy, inclusion: { in: STRATEGY }
  validates :resource_class, inclusion: { in: RESOURCE_CLASS }
  validates :category, inclusion: { in: CATEGORIES }
  validates :brokerage_type, inclusion: { in: BROKERAGE_TYPE }
  validates :payment_to, inclusion: { in: PAYMENT_TO }
  validates :ladders, copy_errors_from_child: true
  validates_with IncentiveSchemeValidator

  accepts_nested_attributes_for :ladders, allow_destroy: true

  def self.user_based_scope(user, params = {})
    custom_scope = {}
    unless user.role.in?(User::ALL_PROJECT_ACCESS + %w(channel_partner))
      custom_scope.merge!({project_id: {"$in": Project.all.pluck(:id)}})
    end
    custom_scope
  end

end
