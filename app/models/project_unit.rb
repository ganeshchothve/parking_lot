class ProjectUnit
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable

  def self.blocking_amount
    30000
  end

  # These fields are globally utlised on the server side
  field :name, type: String
  field :base_price, type: Float
  field :booking_price, type: Float
  field :status, type: String, default: 'available'
  field :selldo_id, type: String

  # These fields majorly are pulled from sell.do and may be used on the UI
  field :project_id, type: String
  field :data_attributes, type: Array, default: []
  field :costs, type: Array
  field :project_tower_name, type: String
  field :project_name, type: String
  field :developer_name, type: String
  field :bedrooms, type: Integer
  field :bathrooms, type: Integer
  field :saleable, type: Float
  field :carpet, type: Float
  field :loading, type: Float
  field :base_rate, type: Float
  field :sub_type, type: String
  field :type, type: String
  field :covered_area, type: Float
  field :terrace_area, type: Float
  field :category, type: String
  field :client_id, type: String
  field :developer_id, type: String
  field :project_id, type: String
  field :project_tower_id, type: String
  field :unit_configuration_id, type: String
  field :configuration_type, type: String
  field :transaction_type, type: String
  field :registration_date, type: Date
  field :floor, type: String
  field :assigned_to, type: String
  field :broker, type: String
  field :team, type: String
  field :date_of_possession, type: Date
  field :possession_status, type: String
  field :seller_type, type: String
  field :is_negotiable, type: Boolean
  field :amenities, type: Array
  field :parking, type: String
  field :docs_verified, type: Boolean
  field :verification_date, type: String
  field :property_inspected, type: Boolean
  field :suitable_for, type: String
  field :entrance, type: String
  field :furnishing, type: String
  field :flooring, type: String
  field :facing, type: String
  field :unit_facing_direction, type: String
  field :maintenance_per_month, type: Float
  field :property_tax, type: Float
  field :total_property_tax_month, type: Float
  field :registration_cost, type: Float
  field :transfer_charge, type: Float
  field :project_status, type: String
  field :city, type: String
  field :state, type: String
  field :country, type: String
  field :resale, type: Boolean
  field :owner_count, type: Integer
  field :posted_by, type: String

  belongs_to :project
  belongs_to :user, optional: true
  has_many :receipts
  has_many :user_requests
  has_and_belongs_to_many :user_kycs

  validates :client_id, :project_id, :project_tower_id, :bedrooms, :bathrooms, :saleable, :carpet, :loading, :base_rate, :category, :type, presence: true
  validates :status, :name, :base_price, :booking_price, presence: true
  validates :base_price, numericality: { greater_than: 0 }
  validates :booking_price, numericality: { greater_than: ProjectUnit.blocking_amount }
  validates :status, inclusion: {in: Proc.new{ ProjectUnit.available_statuses.collect{|x| x[:id]} } }
  validates :user_id, :user_kyc_ids, presence: true, if: Proc.new { |unit| ['available', 'not_available'].exclude?(unit.status) }

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
    # TODO: write the actual code here
    selldo_response_status = 200
    return (selldo_response_status == 200)
  end

  def process_payment!(receipt)
    if ['success', 'clearance_pending'].include?(receipt.status)
      if self.pending_balance({strict: true}) == 0
        self.status = 'booked_confirmed'
      elsif self.total_amount_paid > ProjectUnit.blocking_amount
        self.status = 'booked_tentative'
      elsif receipt.total_amount >= ProjectUnit.blocking_amount && self.status == 'hold'
        self.status = 'blocked'
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
    if params[:fltrs].present?
      # TODO: handle search here
    end
    selector[:name] = ::Regexp.new(::Regexp.escape(params[:q]), 'i') if params[:q].present?
    self.where(selector)
  end
end
