class VariableIncentiveScheme
  include Mongoid::Document
  include Mongoid::Timestamps
  include VariableIncentiveSchemeStateMachine
  extend FilterByCriteria
  include ArrayBlankRejectable
  include RangeUtils
  include InsertionStringMethods

  field :name, type: String
  field :days_multiplier, type: Float, default: 0.0
  field :total_bookings_multiplier, type: Float, default: 0.0
  field :min_incentive, type: Float, default: 0.0
  field :scheme_days, type: Integer, default: 0
  field :average_revenue_or_bookings, type: Float, default: 0.0
  field :max_expense_percentage, type: Float, default: 0.0
  field :start_date, type: Date
  field :end_date, type: Date
  field :project_ids, type: Array, default: []
  field :total_bookings, type: Integer, default: 0
  field :total_inventory, type: Integer, default: 0
  field :status, type: String, default: "draft"

  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User"

  validates :name, :days_multiplier, :total_bookings_multiplier, :min_incentive, :scheme_days, presence: true
  validates :average_revenue_or_bookings, :max_expense_percentage, :start_date, :end_date, presence: true
  validates :days_multiplier, :total_bookings_multiplier, :min_incentive, :average_revenue_or_bookings, :max_expense_percentage, :total_bookings, :total_inventory,  numericality: { greater_than_or_equal_to: 0}
  validates_with VariableIncentiveSchemeValidator

  scope :filter_by_name, ->(name) { where(name: ::Regexp.new(::Regexp.escape(name), 'i')) }
  scope :filter_by_search, ->(search) { where(name: ::Regexp.new(::Regexp.escape(search), 'i')) }
  scope :filter_by_status, ->(status) { where(status: status) }
  scope :filter_by_project_id, ->(project_id) { where(project_ids: {"$in": [project_id]}) }
  scope :filter_by_project_ids, ->(project_ids){ project_ids.present? ? where(project_id: {"$in": project_ids}) : all }
  scope :filter_by_date_range, ->(date) {start_date, end_date = date.split(' - '); where(starts_on: {'$lte': end_date}, ends_on: {'$gte': start_date})}

  def project_names
    return "" if project_ids.blank?
    Project.in(id: project_ids).pluck(:name).join(",")
  end

  def self.user_based_scope(user, params = {})
    custom_scope = {}
    unless user.role.in?(User::ALL_PROJECT_ACCESS + %w(channel_partner))
      custom_scope.merge!({project_id: {"$in": Project.all.pluck(:id)}})
    end
    custom_scope
  end
end
