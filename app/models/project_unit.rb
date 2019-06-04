class ProjectUnit
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include ApplicationHelper
  extend ApplicationHelper
  include InsertionStringMethods
  include PriceCalculator

  STATUS = %w(available not_available hold blocked error)

  # These fields are globally utlised on the server side
  field :name, type: String
  field :erp_id, type: String
  field :agreement_price, type: Integer
  field :all_inclusive_price, type: Integer
  field :booking_price, type: Integer
  field :status, type: String, default: 'available'
  field :available_for, type: String, default: 'user'
  field :blocked_on, type: Date
  field :auto_release_on, type: Date
  field :held_on, type: DateTime
  field :base_rate, type: Float

  # These fields majorly are pulled from sell.do and may be used on the UI
  field :developer_name, type: String
  field :project_name, type: String
  field :project_tower_name, type: String
  field :unit_configuration_name, type: String

  field :selldo_id, type: String

  field :floor_rise, type: Float
  field :floor, type: Integer
  field :floor_order, type: Integer
  field :bedrooms, type: Float
  field :bathrooms, type: Float
  field :carpet, type: Float
  field :saleable, type: Float
  field :sub_type, type: String
  field :type, type: String
  field :unit_facing_direction, type: String
  field :primary_user_kyc_id, type: BSON::ObjectId
  field :blocking_amount, type: Integer, default: 30_000

  attr_accessor :processing_user_request, :processing_swap_request

  enable_audit(
    indexed_fields: %i[project_id project_tower_id unit_configuration_id booking_portal_client_id selldo_id developer_id],
    audit_fields: %i[erp_id status available_for blocked_on auto_release_on held_on primary_user_kyc_id base_rate]
  )

  belongs_to :project
  belongs_to :developer
  belongs_to :project_tower
  belongs_to :unit_configuration
  belongs_to :booking_portal_client, class_name: 'Client'
  belongs_to :user, optional: true
  belongs_to :phase, optional: true
  belongs_to :primary_user_kyc, optional: true

  # remove optional true when all project units are assigned to some phase

  has_many :receipts
  has_many :user_requests
  has_and_belongs_to_many :user_kycs
  has_and_belongs_to_many :users
  has_many :smses, as: :triggered_by, class_name: 'Sms'
  has_many :emails, as: :triggered_by, class_name: 'Email'
  has_many :booking_details
  embeds_many :costs, as: :costable
  embeds_many :data, as: :data_attributable
  embeds_many :parameters, as: :parameterizable

  has_many :assets, as: :assetable

  accepts_nested_attributes_for :data, :parameters, :assets, :costs, allow_destroy: true

  validates :agreement_price, :all_inclusive_price, :booking_price, :project_id, :project_tower_id, :unit_configuration_id, :floor, :floor_order, :bedrooms, :bathrooms, :carpet, :saleable, :type, :developer_name, :project_name, :project_tower_name, :unit_configuration_name, presence: true
  validates :status, :name, :erp_id, presence: true
  validates :status, inclusion: { in: proc { ProjectUnit.available_statuses.collect { |x| x[:id] } } }
  validates :available_for, inclusion: { in: proc { ProjectUnit.available_available_fors.collect { |x| x[:id] } } }
  validate :pan_uniqueness

  delegate :name, to: :phase, prefix: true, allow_nil: true

  def ds_name
    "#{project_tower_name} | #{name} | #{bedrooms} BHK"
  end

  def make_available
    self.status = 'available' if available_for == 'user'
    self.status = 'employee' if available_for == 'employee'
    self.status = 'management' if available_for == 'management'
    # GENERICTODO: self.base_rate = upgraded rate based on timely upgrades
    SelldoLeadUpdater.perform_async(user_id.to_s, 'hold_payment_dropoff')
  end

  #
  # This function return true or false when unit is ready for booking.
  #
  #
  # @return [Boolean] True/False
  #
  def available?
    %w[available employee management].include?(status)
  end

  def blocked?
    status == 'blocked'
  end

  def calculated_parameters
    out = {}
    parameters.each { |c| out[c.key] = c.value }
    out.with_indifferent_access
  end

  #
  # update project unit permitted scheme query
  # - scheme should be available for same project_tower
  # - scheme should be approved
  # - scheme can be apply by only given user role or it empty( any one can apply)
  # - Scheme can be apply for those user which attached with project.
  # - Scheme can be apply for those user role which attached with project.
  #
  # @param [User] _user Which is going to book unit.
  #
  # @return [Scheme collection] permitted schemes for booking.
  #
  def permitted_schemes(_user=nil)
    _user ||= self.booking_detail.try(:user)
    _selector = {
      project_tower_id: self.project_tower_id,
      status: "approved",
      '$and' => [{
        '$or' => [
          { can_be_applied_by: nil },
          { can_be_applied_by: [] },
          { can_be_applied_by: _user.try(:role) || [] }
        ]
      }]
    }
    if _user
      _selector['$and'] << { '$or' => [ {user_ids: nil }, {user_ids: []},
          { user_ids: _user.id } ] }
      _selector['$and'] <<  { '$or' => [ {user_role: nil}, { user_role: []}, {user_role: _user.role } ]}
    end
    Scheme.where(_selector)
  end

  def self.user_based_available_statuses(user)
    statuses = if user.present?
                 if user.role?('management_user')
                   %w[available employee management]
                 elsif user.role?('employee_user')
                   %w[available employee]
                 else
                   ['available']
                            end
               else
                 ['available']
               end
    statuses
  end

  def user_based_status(user)
    if ProjectUnit.booking_stages.include?(status) || status == 'hold'
      'booked'
    else
      if user.role?('user')
        if status == 'available'
          return 'available'
        else
          return 'not_available'
        end
      end
      if user.role?('employee_user')
        if status == 'available' || status == 'employee'
          return 'available'
        else
          return 'not_available'
        end
      end
      if user.role?('management_user')
        if status == 'available' || status == 'employee' || status == 'management'
          return 'available'
        else
          return 'not_available'
        end
      end
      if status == 'available'
        return 'available'
      else
        return 'not_available'
      end
    end
  end

  def self.available_statuses
    out = [
      { id: 'available', text: 'Available' },
      { id: 'under_negotiation', text: 'Under negotiation' },
      { id: 'negotiation_failed', text: 'Negotiation failed' },
      { id: 'not_available', text: 'Not Available' },
      { id: 'error', text: 'Error' },
      { id: 'hold', text: 'Hold' },
      { id: 'blocked', text: 'Blocked' },
      { id: 'booked_tentative', text: 'Tentative Booked' },
      { id: 'booked_confirmed', text: 'Confirmed Booked' }
    ]
    if current_client.enable_company_users?
      out += [
        { id: 'management', text: 'Management Blocking' },
        { id: 'employee', text: 'Employee Blocking' }
      ]
    end
    out
  end

  def self.available_available_fors
    [
      { id: 'user', text: 'User' },
      { id: 'management', text: 'Management' },
      { id: 'employee', text: 'Employee' }
    ]
  end

  def self.booking_stages
    %w[blocked booked_tentative booked_confirmed]
  end

  def self.cost_adjustment_fields
    %i[base_rate floor_rise agreement_price]
  end

  def can_block?(user)
    (status == 'hold' && user_id == user.id) || user_based_status(user) == 'available'
  end

  def self.build_criteria(params = {})
    selector = {}
    if params[:fltrs].present? && params[:fltrs][:_id].blank?
      # TODO: handle search here
      if params[:fltrs][:status].present?
        if params[:fltrs][:status].is_a?(Array)
          selector = { status: { "$in": params[:fltrs][:status] } }
        elsif params[:fltrs][:status].is_a?(ActionController::Parameters)
          selector = { status: params[:fltrs][:status].to_unsafe_h }
        else
          selector = { status: params[:fltrs][:status] }
        end
      end
      if params[:fltrs][:project_tower_id].present?
        selector[:project_tower_id] = params[:fltrs][:project_tower_id]
      end
      if params[:fltrs][:unit_facing_direction].present?
        selector[:unit_facing_direction] = params[:fltrs][:unit_facing_direction]
      end
      if params[:fltrs][:floor].present?
        selector[:floor] = params[:fltrs][:floor]
      end
      if params[:fltrs][:floor_order].present?
        selector[:floor_order] = params[:fltrs][:floor_order]
      end
      if params[:fltrs][:carpet].present?
        carpet = params[:fltrs][:carpet].split('-')
        selector[:carpet] = { '$gte' => carpet.first.to_i, '$lte' => carpet.last.to_i }
      end
      if params[:fltrs][:saleable].present?
        saleable = params[:fltrs][:saleable].split('-')
        selector[:saleable] = { '$gte' => saleable.first.to_i, '$lte' => saleable.last.to_i }
      end
      if params[:fltrs][:agreement_price].present?
        budget = params[:fltrs][:agreement_price].split('-')
        selector[:agreement_price] = { '$gte' => budget.first.to_i, '$lte' => budget.last.to_i }
      end
      if params[:fltrs][:all_inclusive_price].present?
        budget = params[:fltrs][:all_inclusive_price].split('-')
        selector[:all_inclusive_price] = { '$gte' => budget.first.to_i, '$lte' => budget.last.to_i }
      end
      if params[:fltrs][:bedrooms].present?
        selector[:bedrooms] = params[:fltrs][:bedrooms].to_f
      end
      if params[:fltrs][:bathrooms].present?
        selector[:bathrooms] = params[:fltrs][:bathrooms].to_f
      end
    elsif params[:fltrs].present? && params[:fltrs][:_id].present?
      selector[:id] = params[:fltrs][:_id]
    end

    selector[:name] = ::Regexp.new(::Regexp.escape(params[:search]), 'i') if params[:search].present?
    where(selector)
  end

  def ui_json
    hash = as_json
    @@keys.each do |k, _klass|
      hash[k] = send(k)
    end
    hash
  end

  def booking_detail
    BookingDetail.where(project_unit_id: id).nin(status: %w[cancelled swapped]).first
  end

  def blocking_days
    current_client.blocking_days
  end

  def holding_minutes
    current_client.holding_minutes
  end

  def booking_detail_scheme
    scheme
  end

  def scheme
    return @scheme if @scheme.present?

    @scheme = booking_detail.try(:booking_detail_scheme) if self.available?

    @scheme = project_tower.default_scheme if @scheme.blank?
    @scheme
  end

  def cost_sheet_template(scheme_id = nil)
    scheme_id.present? ? Scheme.find(scheme_id).cost_sheet_template : scheme.cost_sheet_template
  end

  def payment_schedule_template(scheme_id = nil)
    scheme_id.present? ? Scheme.find(scheme_id).payment_schedule_template : scheme.payment_schedule_template
  end

  def pending_booking_detail_scheme
    if booking_detail.present? && (%w[hold].include?(status) || self.class.booking_stages.include?(status))
      BookingDetailScheme.where(booking_detail_id: booking_detail.id).in(status: 'draft').desc(:created_at).first
    end
  end

  def pending_balance
    booking_detail.try(:pending_balance).to_f
  end

  private

  def pan_uniqueness
    if user_id.present? && user.unused_user_kyc_ids(id).blank?
      errors.add :primary_user_kyc_id, 'already has a booking'
    end
  end
end
