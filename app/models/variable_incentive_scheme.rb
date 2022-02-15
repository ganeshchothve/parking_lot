class VariableIncentiveScheme
  include Mongoid::Document
  include Mongoid::Timestamps
  include IncentiveSchemeStateMachine
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

  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User"

  validates :name, :days_multiplier, :total_bookings_multiplier, :min_incentive, :scheme_days, presence: true
  validates :average_revenue_or_bookings, :max_expense_percentage, :start_date, :end_date, :project_ids, presence: true
  validates_with VariableIncentiveSchemeValidator

  def self.user_based_scope(user, params = {})
    custom_scope = {}
    unless user.role.in?(User::ALL_PROJECT_ACCESS + %w(channel_partner))
      custom_scope.merge!({project_id: {"$in": Project.all.pluck(:id)}})
    end
    custom_scope
  end
end
