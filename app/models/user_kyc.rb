class UserKyc
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include ApplicationHelper
  # include SyncDetails
  include CrmIntegration
  extend FilterByCriteria

  # Add different types of documents which are uploaded on user_kyc
  THIRD_PARTY_REFERENCE_IDS = %w(reference_id)
  DOCUMENT_TYPES = []
  OCCUPATIONS = ['salaried', 'self_employed', 'business', 'owner', 'retired', 'home_maker', 'other_company']

  field :salutation, type: String, default: 'Mr.'
  field :first_name, type: String
  field :last_name, type: String
  field :email, type: String
  field :phone, type: String
  field :dob, type: Date
  field :pan_number, type: String
  field :aadhaar, type: String
  field :anniversary, type: Date
  field :education_qualification, type: String
  field :designation, type: String
  field :customer_company_name, type: String
  field :configurations, type: Array, default: []
  field :number_of_units, type: Integer
  field :preferred_floors, type: Array, default: []
  field :budget, type: Integer
  field :comments, type: String
  field :occupation, type: String

  field :nri, type: Boolean, default: false
  field :oci, type: String

  field :poa, type: Boolean, default: false
  field :poa_details, type: String
  field :poa_details_phone_no, type: String

  field :is_company, type: Boolean, default: false
  field :gstn, type: String
  field :company_name, type: String

  field :existing_customer, type: Boolean, default: false
  field :existing_customer_name, type: String
  field :existing_customer_project, type: String
  field :erp_id, type: String, default: ''

  enable_audit(
    associated_with: ['user'],
    indexed_fields: [:creator_id],
    audit_fields: %i[creator_id pan_number aadhaar is_company gstn company_name]
  )

  has_many :assets, as: :assetable
  has_one :bank_detail, as: :bankable, validate: false
  has_many :addresses, as: :addressable, validate: false
  belongs_to :user
  belongs_to :lead
  belongs_to :receipt, optional: true
  belongs_to :creator, class_name: 'User'
  has_and_belongs_to_many :project_units
  has_and_belongs_to_many :booking_details

  delegate :name, to: :bank_detail, prefix: true, allow_nil: true
  accepts_nested_attributes_for :bank_detail
  accepts_nested_attributes_for :addresses#, reject_if: proc { |attributes| attributes['one_line_address'].blank? }

  validates :first_name, :last_name, :email, :phone, presence: true
  # validates :pan_number, presence: true, unless: Proc.new{ |kyc| kyc.nri? }, reduce: true
  validates :oci, presence: true, if: Proc.new{ |kyc| kyc.nri? }
  # validates :email, uniqueness: {scope: :lead_id}, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP } , allow_blank: true
  # validates :pan_number, :aadhaar, uniqueness: {scope: :lead_id}, allow_blank: true, reduce: true
  # validates :phone, uniqueness: {scope: [:aadhaar, :lead_id] }
  validates :phone, phone: { possible: true, types: %i[voip personal_number fixed_or_mobile mobile fixed_line premium_rate] }, allow_blank: true
  # validates :phone, uniqueness: {scope: :aadhaar}, phone: true # TODO: we can remove phone validation, as the validation happens in
  validates :configurations, array: {inclusion: {allow_blank: true, in: Proc.new{ |kyc| UserKyc.available_configurations(kyc.lead_id.to_s).collect{|x| x[:id]} } }}
  validates :preferred_floors, array: {inclusion: {allow_blank: true, in: Proc.new{ |kyc| UserKyc.available_preferred_floors.collect{|x| x[:id]} } }}
  validates :pan_number, format: { with: /[A-Z]{3}[ABCGFHLJPTE][A-Z][0-9]{4}[A-Z]/i, message: 'is not in a format of AAAAA9999A' }, reduce: true, allow_blank: true
  validates :aadhaar, format: { with: /\A\d{12}\z/i, message: 'is not a valid aadhaar number' }, allow_blank: true
  validates :company_name, presence: true, if: proc { |kyc| kyc.is_company? }
  validates :poa_details, presence: true, if: proc { |kyc| kyc.poa? }
  validates :existing_customer_name, :existing_customer_project, presence: true, if: proc { |kyc| kyc.existing_customer? }
  validates :salutation, inclusion: { in: proc { UserKyc.available_salutations.collect { |x| x[:id] } } }, allow_blank: true
  validates :erp_id, uniqueness: true, allow_blank: true
  validates :addresses, copy_errors_from_child: true

  scope :filter_by_user_id, ->(user_id) { where(user_id: user_id) }
  scope :filter_by_lead_id, ->(lead_id){ where(lead_id: lead_id)}


  default_scope -> { desc(:created_at) }

  def name_in_error
    "#{name} - #{email}"
  end

  def name
    begin
      _salutation = UserKyc.available_salutations.find { |x| x[:id] == salutation }[:text]
    rescue StandardError
      _salutation = ''
    end
    "#{_salutation} #{first_name} #{last_name}"
  end

  alias :resource_name :name

  def api_json
    # extract phone and country code from phone field
    phone = Phonelib.parse(kyc.phone)
    country_code = phone.country_code
    kyc_phone = phone.national(false).sub(/^0/, '')

    hash = {
      applicant_id: kyc.id.to_s,
      salutation: kyc.salutation,
      first_name: kyc.first_name,
      last_name: kyc.last_name,
      email: kyc.email,
      country_code_primary_phone: country_code,
      phone: kyc_phone,
      pan_no: kyc.pan_number,
      dob: (kyc.dob.strftime('%Y-%m-%d') rescue nil),
      anniversary: (kyc.anniversary.strftime('%Y-%m-%d') rescue nil),
      nri: kyc.nri ? 'NRI' : 'Indian',
      aadhaar: kyc.aadhaar,
      house_number: kyc.house_number,
      street: kyc.street,
      city: kyc.city,
      state: kyc.state,
      country: kyc.country,
      zip: kyc.postal_code,
      marital_status: nil,
      passport_number: nil,
      gender: nil,
      coapplicant_type: coapplicant_type
    }
  end

  def sync(erp_model, sync_log)
    Api::UserKycDetailsSync.new(erp_model, self, sync_log).execute
  end

  class << self
    def available_salutations
      [
        { id: 'Mr.', text: 'Mr.' },
        { id: 'Mrs.', text: 'Mrs.' },
        { id: 'Ms.', text: 'Ms.' },
        { id: 'Brig.', text: 'Brig.' },
        { id: 'Captain', text: 'Captain' },
        { id: 'Col', text: 'Col' },
        { id: 'Dr.', text: 'Dr.' },
        { id: 'Maharaj', text: 'Maharaj' },
        { id: 'Prof.', text: 'Prof.' }
      ]
    end

    def available_configurations(lead_id = nil)
      lead = Lead.where(id: lead_id).first
      configurations = []

      if lead.present?
        unit_configurations = lead.project.unit_configurations.map{|uc| uc.name }.uniq.compact rescue []
        configurations = unit_configurations.map{|a| { text: a, id: a } }
      end
      
      if configurations.empty?
        configurations = [
          { text: '1 BHK', id: '1' },
          { text: '1.5 BHK', id: '1.5' },
          { text: '2 BHK', id: '2' },
          { text: '2.5 BHK', id: '2.5' },
          { text: '3 BHK', id: '3' },
          { text: '3.5 BHK', id: '3.5' },
          { text: '4 BHK', id: '4' },
          { text: '4.5 BHK', id: '4.5' },
          { text: '5 BHK', id: '5' },
          { text: '5.5 BHK', id: '5.5' },
          { text: '6 BHK', id: '6' },
          { text: '7 BHK', id: '7' }
        ]
      end
      configurations
    end

    def available_preferred_floors
      if ProjectTower.count > 0
        (1..ProjectTower.max(:total_floors)).to_a.collect { |x| { id: x.to_s, text: x.to_s } }
      else
        (1..1).to_a.collect { |x| { id: x.to_s, text: x.to_s } }
      end
    end

    def user_based_scope(user, params = {})
      custom_scope = {}
      if params[:lead_id].blank? && !user.buyer?
        if user.role?('channel_partner')
          custom_scope = { lead_id: { "$in": Lead.where(referenced_manager_ids: user.id).distinct(:id) } }
        elsif user.role?('cp_admin')
          custom_scope = { lead_id: { "$in": Lead.where(manager_id: { "$nin": [nil, ''] }).distinct(:id) } }
        elsif user.role?('cp')
          channel_partner_ids = User.where(role: 'channel_partner').where(manager_id: user.id).distinct(:id)
          custom_scope = { lead_id: { "$in": Lead.in(referenced_manager_ids: channel_partner_ids).distinct(:id) } }
        end
      end

      custom_scope = { lead_id: params[:lead_id] } if params[:lead_id].present?
      custom_scope = { user_id: user.id } if user.buyer?

      custom_scope[:project_unit_id] = params[:project_unit_id] if params[:project_unit_id].present?
      custom_scope
    end
  end
end
