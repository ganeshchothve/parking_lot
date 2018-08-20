class ProjectUnit
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include ApplicationHelper
  include InsertionStringMethods
  include CostCalculator

  # These fields are globally utlised on the server side
  field :name, type: String
  field :erp_id, type: String
  field :agreement_price, type: Integer
  field :all_inclusive_price, type: Integer
  field :status, type: String, default: 'available'
  field :available_for, type: String, default: 'user'
  field :blocked_on, type: Date
  field :auto_release_on, type: Date
  field :held_on, type: DateTime
  field :applied_discount_rate, type: Float, default: 0
  field :applied_discount_id, type: String
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
  field :payment_schedule_template_id, type: BSON::ObjectId
  field :cost_sheet_template_id, type: BSON::ObjectId

  attr_accessor :processing_user_request, :processing_swap_request

  enable_audit({
    indexed_fields: [:project_id, :project_tower_id, :unit_configuration_id, :client_id, :booking_portal_client_id, :selldo_id, :developer_id],
    audit_fields: [:erp_id, :status, :available_for, :blocked_on, :auto_release_on, :held_on, :applied_discount_rate, :applied_discount_id, :primary_user_kyc_id, :base_rate]
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
  embeds_many :costs, as: :costable
  embeds_many :data, as: :data_attributable

  has_many :assets, as: :assetable

  accepts_nested_attributes_for :data, :costs, allow_destroy: true

  validates :client_id, :agreement_price, :all_inclusive_price, :project_id, :project_tower_id, :unit_configuration_id, :floor, :floor_order, :bedrooms, :bathrooms, :carpet, :saleable, :type, :developer_name, :project_name, :project_tower_name, :unit_configuration_name, :payment_schedule_template_id, :cost_sheet_template_id, presence: true
  validates :status, :name, :erp_id, presence: true
  validates :status, inclusion: {in: Proc.new{ ProjectUnit.available_statuses.collect{|x| x[:id]} } }
  validates :available_for, inclusion: {in: Proc.new{ ProjectUnit.available_available_fors.collect{|x| x[:id]} } }
  validates :user_id, :primary_user_kyc_id, presence: true, if: Proc.new { |unit| ['available', 'not_available', 'management', 'employee'].exclude?(unit.status) }

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

    SelldoLeadUpdater.perform_async(self.user_id.to_s, "hold_payment_dropoff")
  end

  def calculated_costs
    out = {}
    costs.each{|c| out[c.key] = c.value }
    out
  end

  def calculated_data
    out = {}
    data.each{|c| out[c.key] = c.value }
    out
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
    if ["hold", "blocked", "booked_tentative", "booked_confirmed"].include?(self.status)
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
    [
      {id: 'available', text: 'Available'},
      {id: 'not_available', text: 'Not Available'},
      {id: 'management', text: 'Management Blocking'},
      {id: 'employee', text: 'Employee Blocking'},
      {id: 'error', text: 'Error'},
      {id: 'hold', text: 'Hold'},
      {id: 'blocked', text: 'Blocked'},
      {id: 'booked_tentative', text: 'Tentative Booked'},
      {id: 'booked_confirmed', text: 'Confirmed Booked'}
    ]
  end

  def self.available_available_fors
    [
      {id: "user", text: "User"},
      {id: "management", text: "Management"},
      {id: "employee", text: "Employee"}
    ]
  end

  def process_payment!(receipt)
    if ['success', 'clearance_pending'].include?(receipt.status)
      if self.pending_balance({strict: true}) <= 0
        self.status = 'booked_confirmed'
      elsif self.total_amount_paid > current_client.blocking_amount
      	if self.status != 'booked_tentative'
          self.status = 'booked_tentative'
      	end
      elsif receipt.total_amount >= current_client.blocking_amount && (self.status == "hold" || self.user_based_status(self.user) == "available")
        if (self.user == receipt.user && self.status == 'hold') || self.user_based_status(self.user) == "available"
          self.status = 'blocked'
        else
          receipt.project_unit_id = nil
          receipt.save
        end
      end
      # Send payments data to Sell.Do CRM
      # SelldoReceiptPusher.perform_async(receipt.id.to_s, Time.now.to_i)
    elsif receipt.status == 'failed'
      # if the unit has any successful or clearance_pending payments other than this, we keep it still blocked
      # else we just release the unit
      if self.pending_balance == self.booking_price # not success or clearance_pending receipts tagged against this unit
        if self.status == 'hold'
          self.make_available
          self.user_id = nil
        else
          # TODO: we should display a message on the UI before someone marks the receipt as 'failed'. Because the unit might just get released
          self.status = 'error'
        end
      end
    end
    self.save(validate: false)
  end

  def self.build_criteria params={}
    selector = {}
    if params[:fltrs].present?
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
    end
    selector[:name] = ::Regexp.new(::Regexp.escape(params[:q]), 'i') if params[:q].present?
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
    BookingDetail.where(project_unit_id: self.id).ne(status: "cancelled").first
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

  def payment_schedule_template
    Template::PaymentScheduleTemplate.find self.payment_schedule_template_id
  end

  def cost_sheet_template
    Template::CostSheetTemplate.find self.cost_sheet_template_id
  end
end
