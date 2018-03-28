class ProjectUnit
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable

  def self.blocking_amount
    30000
  end

  def self.total_booked_revenue
    ProjectUnit.where(status: "booked").sum(:agreement_price)
  end

  def blocking_days
    if self.blocking_payment.present?
      if self.blocking_payment.payment_mode == "online"
        7
      else
        10
      end
    else
      7
    end
  end

  def self.holding_minutes
    10.minutes
  end

  def self.booking_price_percent_of_agreement_price
    0.098
  end

  def self.tds_amount_percent_of_agreement_price
    0.001
  end

  # These fields are globally utlised on the server side
  field :name, type: String
  field :sfdc_id, type: String
  field :agreement_price, type: Integer
  field :booking_price, type: Integer
  field :status, type: String, default: 'available'
  field :blocked_on, type: Date
  field :auto_release_on, type: Date
  field :held_on, type: DateTime
  field :tds_amount, type: Float

  # These fields majorly are pulled from sell.do and may be used on the UI
  field :client_id, type: String
  field :developer_id, type: String
  field :project_id, type: String
  field :project_tower_id, type: String
  field :unit_configuration_id, type: String
  field :data_attributes, type: Array, default: []
  field :selldo_id, type: String
  field :maintenance_per_month, type: Float
  field :property_tax, type: Float
  field :total_property_tax_month, type: Float
  field :registration_cost, type: Float
  field :transfer_charge, type: Float
  field :costs, type: Array, default: []
  field :customized_additional_costs, type: Hash
  field :customized_extra_costs, type: Hash
  field :customized_gov_costs, type: Array
  field :customized_grace_period, type: Integer
  field :customized_interest_percentage, type: Integer
  field :calculated_agreement_value, type: Float
  field :images, type: Array

  embeds_many :project_unit_state_changes

  @@keys =  {project_tower_name: "String", project_name: "String", developer_name: "String", bedrooms: "Float", bathrooms: "Float", saleable: "Float", carpet: "Float", loading: "Float", base_price: "Float", base_rate: "Float", sub_type: "String", type: "String", covered_area: "Float", terrace_area: "Float", category: "String",developer_id: "String",configuration_type: "String",construction_status: "String",transaction_type: "String",registration_date: "Date",floor: "Integer",assigned_to: "String",broker: "String",team: "String",date_of_possession: "Date",possession_status: "String",seller_type: "String",is_negotiable: "Boolean",amenities: "Hash",parking: "String",docs_verified: "Boolean",verification_date: "String",property_inspected: "Boolean",suitable_for: "String",entrance: "String",furnishing: "String",flooring: "String",facing: "String",unit_facing_direction: "String",project_status: "String",city: "String",state: "String",country: "String",resale: "Boolean",owner_count: "Integer",posted_by: "String",unit_configuration_id: "String",unit_configuration_name: "String"}

  @@keys.each do |k, klass|
    define_method(k) do
      if self.data_attributes.collect{|x| x['n']}.include?("#{k}")
        val = self.data_attributes.find { |h| h['n'] == "#{k}" }['v']
        case "#{klass}"
        when "Hash"
          val
        when "String"
          val
        when "Integer"
          val.to_i
        when "Float"
          val.to_f
        when "Boolean"
          if(val == "true" || val == true)
            true
          else
            false
          end
        when "Date"
          if(!val.blank?)
            Date.parse(val)
          end
        end
      elsif "#{klass}" == "String"
        nil
      elsif "#{klass}" == "Integer"
        nil
      elsif "#{klass}" == "Float"
        nil
      elsif "#{klass}" == "Array"
        []
      elsif "#{klass}" == "Hash"
        {}
      else
        nil
      end
    end
    define_method("#{k}=") do |arg|
      val = arg
      case "#{klass}"
      when "String"
        val = arg
      when "Integer"
        val = arg.to_i
      when "Float"
        val = arg.to_f
      when "Array"
        val = arg
      when "Hash"
        val = arg
      when "Boolean"
        if(val == "true" || val == true)
          true
        else
          false
        end
      when "Date"
        if(!val.blank? && val.class == String)
          Date.parse(val)
        end
      end
      if self.data_attributes.collect{|x| x['n']}.include?("#{k}")
        self.data_attributes.find { |h| h['n'] == "#{k}" }['v'] = val
      else
        self.data_attributes.push({"n" => "#{k}", "v" => val})
      end
    end
  end

  belongs_to :project
  belongs_to :user, optional: true
  has_many :receipts
  has_many :user_requests
  has_and_belongs_to_many :user_kycs

  validates :client_id, :project_id, :project_tower_id, presence: true
  validates :status, :name, :sfdc_id, presence: true
  validates :status, inclusion: {in: Proc.new{ ProjectUnit.available_statuses.collect{|x| x[:id]} } }
  validates :user_id, :user_kyc_ids, presence: true, if: Proc.new { |unit| ['available', 'not_available'].exclude?(unit.status) }

  def blocking_payment
    receipts.where(payment_type: 'blocking').first
  end

  def self.available_statuses
    [
      {id: 'available', text: 'Available'},
      {id: 'not_available', text: 'Not Available'},
      {id: 'error', text: 'Error'},
      {id: 'hold', text: 'Hold'},
      {id: 'blocked', text: 'Blocked'},
      {id: 'booked_tentative', text: 'Tentative Booked'},
      {id: 'booked_confirmed', text: 'Confirmed Booked'}
    ]
  end

  def unit_configuration
    UnitConfiguration.find(self.unit_configuration_id)
  end

  def land_rate
    1000
  end

  def construction_cost
    base_rate + premium_location_charges + floor_rise - land_rate
  end

  def premium_location_charges
    case category
    when "Courtyard Facing"
	100
    when "Outward Facing"
	75
    when "Inward/Another tower"
	0
    when "Garden, sports zone & club facing"
	150
    when "Garden, sports zone, club & swimming pool facing"
	150
    else
	150
    end
  end

  def floor_rise
    floor < 3 ? 0 : (floor-2)*20
  end

  def land_price
    land_rate * saleable
  end

  def construction_price
    construction_cost * saleable
  end

  def wep_price
    150 * saleable
  end

  def clubhouse_amenities_price
    125000
  end

  def corpus_fund
    125 * saleable
  end

  def city_infrastructure_fund
    200 * saleable
  end

  def advance_maintenance_charges
    3 * 12 * saleable
  end

  def car_park_price
    0
  end

  def gst_on_additional_charges
    0.18 * (wep_price + clubhouse_amenities_price + city_infrastructure_fund + advance_maintenance_charges + car_park_price)
  end

  def gst_on_agreement_price
    0.18 * construction_price
  end

  def sub_total
    wep_price + clubhouse_amenities_price + corpus_fund + city_infrastructure_fund + advance_maintenance_charges + car_park_price + gst_on_additional_charges
  end

  def all_inclusive_price
    sub_total + agreement_price + gst_on_agreement_price
  end
  # TODO: reset the userid always if status changes and is available or not_available

  def pending_balance(options={})
    strict = options[:strict] || false
    user_id = options[:user_id] || self.user_id
    if user_id.present?
      receipts_total = Receipt.where(user_id: user_id, project_unit_id: self.id)
      if strict
        receipts_total = receipts_total.where(status: "success")
      else
        receipts_total = receipts_total.in(status: ['clearance_pending', "success"])
      end
      receipts_total = receipts_total.sum(:total_amount)
      return (self.booking_price - receipts_total)
    else
      return nil
    end
  end

  def total_amount_paid
    self.receipts.where(status: 'success').sum(:total_amount)
  end

  def self.sync_trigger_attributes
    ['status', 'user_id']
  end

  def sync_with_third_party_inventory
    # TODO: write the actual code here
    third_party_inventory_response_status = 200
    return (third_party_inventory_response_status == 200)
  end

  def sync_with_selldo
    # TODO: Sell.Do write the actual code here
    # if status == 'booked_tentative' || status == 'booked_confirmed' || status == 'available' update_project_unit_status
    # if status == 'blocked' add_booking
    selldo_response_status = 200
    return (selldo_response_status == 200)
  end

  def process_payment!(receipt)
    if ['success', 'clearance_pending'].include?(receipt.status)
      if self.pending_balance({strict: true}) == 0
        self.status = 'booked_confirmed'
      elsif self.total_amount_paid > ProjectUnit.blocking_amount
        self.status = 'booked_tentative'
      elsif receipt.total_amount >= ProjectUnit.blocking_amount && ['hold', 'available'].include?(self.status)
        if (self.user == receipt.user && self.status == 'hold') || self.status == "available"
          self.status = 'blocked'
        else
          receipt.project_unit_id = nil
          receipt.save(validate: false)
        end
      end
    elsif receipt.status == 'failed'
      # if the unit has any successful or clearance_pending payments other than this, we keep it still blocked
      # else we just release the unit
      if self.pending_balance == self.booking_price # not success or clearance_pending receipts tagged against this unit
        if self.status == 'hold'
          self.status = 'available'
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
    data_attributes_query = []
    if params[:fltrs].present?
      # TODO: handle search here
      if params[:fltrs][:status].present?
        if params[:fltrs][:status].is_a?(Array)
          selector = {status: {"$in": params[:fltrs][:status] }}
        elsif params[:fltrs][:status].is_a?(ActionController::Parameters)
          selector = {status: params[:fltrs][:status].to_hash }
        else
          selector = {status: params[:fltrs][:status] }
        end
      end
      if params[:fltrs][:project_tower_id].present?
        selector[:project_tower_id] = params[:fltrs][:project_tower_id]
      end

      if params[:fltrs][:data_attributes].present?
        if params[:fltrs][:data_attributes][:bedrooms].present?
          data_attributes_query << {data_attributes: {"$elemMatch" =>{"n" => "bedrooms", "v" => params[:fltrs][:data_attributes][:bedrooms].to_i }}}
        end
        if params[:fltrs][:data_attributes][:agreement_price].present?
          budget = params[:fltrs][:data_attributes][:agreement_price].split("-")
          data_attributes_query << {data_attributes: {"$elemMatch" =>{"n" => "agreement_price", "v" => {"$gte" => budget.first.to_i, "$lte" => budget.last.to_i}}}}
        end
      end
    end
    selector[:name] = ::Regexp.new(::Regexp.escape(params[:q]), 'i') if params[:q].present?
    self.where(selector).and(data_attributes_query)
  end

  def unit_configuration
    if self.unit_configuration_id.present?
      UnitConfiguration.find(self.unit_configuration_id)
    else
      nil
    end
  end

  def ui_json
    hash = self.as_json
    hash.delete(:data_attributes)
    @@keys.each do |k, klass|
      hash[k] = self.send(k)
    end
    hash
  end
end
