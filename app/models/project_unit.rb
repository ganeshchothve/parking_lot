class ProjectUnit
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include ApplicationHelper
  extend ApplicationHelper
  include InsertionStringMethods
  include CostCalculator

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
  field :client_id, type: String
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
  field :blocking_amount, type: Integer, default: 30000

  attr_accessor :processing_user_request, :processing_swap_request

  enable_audit({
    indexed_fields: [:project_id, :project_tower_id, :unit_configuration_id, :client_id, :booking_portal_client_id, :selldo_id, :developer_id],
    audit_fields: [:erp_id, :status, :available_for, :blocked_on, :auto_release_on, :held_on, :primary_user_kyc_id, :base_rate]
  })

  belongs_to :project
  belongs_to :developer
  belongs_to :project_tower
  belongs_to :unit_configuration
  belongs_to :booking_portal_client, class_name: 'Client'
  belongs_to :user, optional: true

  has_many :receipts
  has_many :user_requests
  has_and_belongs_to_many :user_kycs
  has_many :smses, as: :triggered_by, class_name: "Sms"
  has_many :emails, as: :triggered_by, class_name: "Email"
  embeds_many :costs, as: :costable
  embeds_many :data, as: :data_attributable
  embeds_many :parameters, as: :parameterizable

  has_many :assets, as: :assetable

  accepts_nested_attributes_for :data, :parameters, :costs, allow_destroy: true

  validates :client_id, :agreement_price, :all_inclusive_price, :booking_price, :project_id, :project_tower_id, :unit_configuration_id, :floor, :floor_order, :bedrooms, :bathrooms, :carpet, :saleable, :type, :developer_name, :project_name, :project_tower_name, :unit_configuration_name, presence: true
  validates :status, :name, :erp_id, presence: true
  validates :status, inclusion: {in: Proc.new{ ProjectUnit.available_statuses.collect{|x| x[:id]} } }
  validates :available_for, inclusion: {in: Proc.new{ ProjectUnit.available_available_fors.collect{|x| x[:id]} } }
  validates :user_id, :primary_user_kyc_id, presence: true, if: Proc.new { |unit| ['available', 'not_available', 'management', 'employee'].exclude?(unit.status) }
  validate :pan_uniqueness

  def ds_name
    "#{project_tower_name} | #{name} | #{bedrooms} BHK"
  end

  def make_available
    if self.available_for == "user"
      self.status = "available"
    end
    if self.available_for == "employee"
      self.status = "employee"
    end
    if self.available_for == "management"
      self.status = "management"
    end

    # GENERICTODO: self.base_rate = upgraded rate based on timely upgrades

    self.user_id = nil
    self.primary_user_kyc_id = nil
    self.user_kyc_ids = []

    SelldoLeadUpdater.perform_async(self.user_id.to_s, "hold_payment_dropoff")
  end

  def calculated_costs
    out = {}
    costs.each{|c| out[c.key] = c.value }
    out.with_indifferent_access
  end

  def calculated_cost(name)
    costs.where(name: name).first.value rescue 0
  end

  def calculated_data
    out = {}
    data.each{|c| out[c.key] = c.value }
    out.with_indifferent_access
  end

  def calculated_parameters
    out = {}
    parameters.each{|c| out[c.key] = c.value }
    out.with_indifferent_access
  end

  def permitted_schemes user=nil
    user ||= self.user
    or_criteria = [{project_tower_id: self.project_tower_id}]
    or_criteria << {user_id: user.id}
    or_criteria << {user_id: nil, user_role: user.role}
    Scheme.where(status: "approved").or("$or" => [{default: true, project_tower_id: self.project_tower_id}, {can_be_applied_by: user.role, "$or": or_criteria}])
  end

  def self.user_based_available_statuses(user)
    if user.present?
      if user.role?("management_user")
        statuses = ["available", "employee", "management"]
      elsif user.role?("employee_user")
        statuses = ["available", "employee"]
      else
        statuses = ["available"]
      end
    else
      statuses = ["available"]
    end
    return statuses
  end

  def user_based_status(user)
    if ProjectUnit.booking_stages.include?(self.status) || self.status == "hold"
      return "booked"
    else
      if user.role?("user")
        if self.status == "available"
          return "available"
        else
          return "not_available"
        end
      end
      if user.role?("employee_user")
        if self.status == "available" || self.status == "employee"
          return "available"
        else
          return "not_available"
        end
      end
      if user.role?("management_user")
        if self.status == "available" || self.status == "employee" || self.status == "management"
          return "available"
        else
          return "not_available"
        end
      end
      if self.status == "available"
        return "available"
      else
        return "not_available"
      end
    end
  end

  def self.available_statuses
    out = [
      {id: 'available', text: 'Available'},
      {id: 'under_negotiation', text: 'Under negotiation'},
      {id: 'negotiation_failed', text: 'Negotiation failed'},
      {id: 'not_available', text: 'Not Available'},
      {id: 'error', text: 'Error'},
      {id: 'hold', text: 'Hold'},
      {id: 'blocked', text: 'Blocked'},
      {id: 'booked_tentative', text: 'Tentative Booked'},
      {id: 'booked_confirmed', text: 'Confirmed Booked'}
    ]
    if current_client.enable_company_users?
      out += [
        {id: 'management', text: 'Management Blocking'},
        {id: 'employee', text: 'Employee Blocking'}
      ]
    end
    out
  end

  def self.available_available_fors
    [
      {id: "user", text: "User"},
      {id: "management", text: "Management"},
      {id: "employee", text: "Employee"}
    ]
  end

  def self.booking_stages
    ["blocked", "booked_tentative", "booked_confirmed"]
  end

  def self.cost_adjustment_fields
    [:base_rate, :floor_rise, :agreement_price]
  end

  def can_block? user
    (self.status == "hold" && self.user_id == user.id) || self.user_based_status(user) == "available"
  end

  def process_payment!(receipt)
    if ['success', 'clearance_pending'].include?(receipt.status)
      if ProjectUnit.booking_stages.include?(self.status) || self.can_block?(receipt.user) || (self.status == "under_negotiation" && self.user_id == receipt.user_id)
        if self.scheme.status == "approved"
          if self.pending_balance({strict: true}) <= 0
            self.status = 'booked_confirmed'
          elsif self.total_amount_paid > self.blocking_amount
              self.status = 'booked_tentative'
          else
            self.status = 'blocked'
          end
        end
      else
        receipt.project_unit_id = nil
        receipt.save
      end
      # Send payments data to Sell.Do CRM
      # SelldoReceiptPusher.perform_async(receipt.id.to_s, Time.now.to_i)
    elsif receipt.status == 'failed'
      # if the unit has any successful or clearance_pending payments other than this, we keep it still blocked
      # else we just release the unit
      if self.pending_balance == self.booking_price # not success or clearance_pending receipts tagged against this unit
        if self.status == 'hold'
          self.make_available
        else
          # TODO: we should display a message on the UI before someone marks the receipt as 'failed'. Because the unit might just get released
          self.status = 'error'
        end
      end
    end
    self.save(validate: false)
  end

  def process_scheme!
    if self.status == "under_negotiation" && self.scheme.status == "approved"
      if self.pending_balance({strict: true}) <= 0
        self.status = 'booked_confirmed'
      elsif self.total_amount_paid > self.blocking_amount
        self.status = 'booked_tentative'
      elsif self.total_tentative_amount_paid >= self.blocking_amount
        self.status = 'blocked'
      end
      self.save(validate: false)
    end
  end

  def self.build_criteria params={}
    selector = {}
    if params[:fltrs].present? && params[:fltrs][:_id].blank?
      # TODO: handle search here
      if params[:fltrs][:status].present?
        if params[:fltrs][:status].is_a?(Array)
          selector = {status: {"$in": params[:fltrs][:status] }}
        elsif params[:fltrs][:status].is_a?(ActionController::Parameters)
          selector = {status: params[:fltrs][:status].to_unsafe_h }
        else
          selector = {status: params[:fltrs][:status] }
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
        carpet = params[:fltrs][:carpet].split("-")
        selector[:carpet] = {"$gte" => carpet.first.to_i, "$lte" => carpet.last.to_i}
      end
      if params[:fltrs][:saleable].present?
        saleable = params[:fltrs][:saleable].split("-")
        selector[:saleable] = {"$gte" => saleable.first.to_i, "$lte" => saleable.last.to_i}
      end
      if params[:fltrs][:agreement_price].present?
        budget = params[:fltrs][:agreement_price].split("-")
        selector[:agreement_price] = {"$gte" => budget.first.to_i, "$lte" => budget.last.to_i}
      end
      if params[:fltrs][:all_inclusive_price].present?
        budget = params[:fltrs][:all_inclusive_price].split("-")
        selector[:all_inclusive_price] = {"$gte" => budget.first.to_i, "$lte" => budget.last.to_i}
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
    self.where(selector)
  end

  def ui_json
    hash = self.as_json
    @@keys.each do |k, klass|
      hash[k] = self.send(k)
    end
    hash
  end

  def booking_detail
    BookingDetail.where(project_unit_id: self.id).nin(status: ["cancelled", "swapped"]).first
  end

  def blocking_days
    current_client.blocking_days
  end

  def holding_minutes
    current_client.holding_minutes
  end

  def primary_user_kyc
    primary_user_kyc_id.present? ? UserKyc.find(primary_user_kyc_id) : nil
  end

  def booking_detail_scheme
    BookingDetailScheme.where(user_id: self.user_id, project_unit_id: self.id).in(status: ["under_negotiation", "draft", "approved"]).desc(:created_at).first
  end

  def scheme
    return @scheme if @scheme.present?

    @scheme = self.booking_detail_scheme

    if @scheme.blank?
      @scheme = project_tower.default_scheme
    end
    @scheme
  end

  def cost_sheet_template scheme_id=nil
    scheme_id.present? ? Scheme.find(scheme_id).cost_sheet_template : self.scheme.cost_sheet_template
  end

  def payment_schedule_template scheme_id=nil
    scheme_id.present? ? Scheme.find(scheme_id).payment_schedule_template : self.scheme.payment_schedule_template
  end

  def pending_booking_detail_scheme
    if ["hold", "under_negotiation"].include?(self.status) || self.class.booking_stages.include?(self.status)
      self.booking_detail_scheme
    end
  end

  private
  def pan_uniqueness
    if self.user_id.present? && self.user.unused_user_kyc_ids(self.id).blank?
      self.errors.add :primary_user_kyc_id, "already has a booking"
    end
  end
end
