class ChannelPartner
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  # include SyncDetails
  include CrmIntegration
  extend FilterByCriteria
  include ChannelPartnerStateMachine
  include ApplicationHelper
  extend ApplicationHelper

  STATUS = %w(active inactive pending rejected)
  THIRD_PARTY_REFERENCE_IDS = %w(reference_id)
  EXPERTISE = %w( rentals retail residential commercial )
  EXPERIENCE = ['0-1 yrs', '1-5 yrs', '5-10 yrs', '10-15 yrs', '15-20 yrs', '20+ yrs']
  DEVELOPERS = [ "Godrej Properties", "Hiranandani", "Lodha Group", "Piramal Realty", "Kanakia", "Mahindra Lifespaces developers", "Kalpataru", "Runwal Group", "Dosti Group", "Wadhwa Group", "Rustomjee", "Puraniks builders", "Adhiraj construction", "L & T Realty", "Arkade Group", "Paradise group", "Chandak", "Marathon Realty", "Raymond Realty", "Damji Shamji Shah", "Shapoorji Pallonji Real Estate", "SD Corp", "Ornate Universal", "Sethia Infrastructure", "Aadi Properties", "Raheja construction", "Tata Housing", "Ajmera", "Adani", "Oberoi Realty", "Acme", "K Raheja", "Hubtown", "Ekta world", "Akshar group", "Raunak group", "JP Infra", "Sunteck Realty Ltd", "Seth Developers", "Kabra developer", "Koltepatil developer" ]
  SERVICES = [ "Media Plan", "Creative", "Execution", "CRM", "Lead Management", "Virtual Presentation Platform" ]

  # Add different types of documents which are uploaded on channel_partner
  DOCUMENT_TYPES = %w[pan_card rera_certificate gst_certificate cheque_scanned_copy company_incorporation_certificate form_10f tax_residency_certificate pe_declaration]
  COMPANY_TYPE = ['Sole Proprietorship', 'Partnership', 'Private Limited', 'Public Limited', 'Others']
  CATEGORY = ['CP Company', 'Individual CP', 'ROTN', 'IRDA', 'Chartered accountants', 'IT Profession']
  SOURCE = ['Internal CP', 'External CP']
  REGION = ['Chennai', 'Bangalore', 'Coimbatore', 'NRI']

  SHORT_FORM = %i(first_name last_name email phone company_name rera_applicable status interested_services)
  FULL_FORM = SHORT_FORM.clone + %i(team_size gst_applicable nri)

  field :title, type: String
  field :first_name, type: String
  field :last_name, type: String
  field :additional_name, type: String
  field :email, type: String
  field :alternate_email, type: String
  field :phone, type: String
  field :alternate_phone, type: String
  field :rera_id, type: String
  field :status, type: String, default: 'inactive'

  field :company_name, type: String
  field :company_type, type: String
  field :company_owner_name, type: String
  field :company_owner_phone, type: String
  field :pan_number, type: String
  field :gstin_number, type: String
  field :aadhaar, type: String
  field :status_change_reason, type: String
  field :category, type: String
  field :source, type: String
  field :website, type: String
  field :region, type: String
  field :erp_id, type: String, default: ''

  field :team_size, type: Integer
  field :rera_applicable, type: Boolean, default: false
  field :gst_applicable, type: Boolean, default: false
  field :nri, type: Boolean, default: false
  field :expertise, type: Array, default: []
  field :experience, type: String
  field :average_quarterly_business, type: Float
  field :developers_worked_for, type: Array, default: []
  field :interested_services, type: Array, default: []
  field :cp_code, type: String

  # Tracking selldo srd for new channel partner registrations.
  field :srd, type: String

  scope :filter_by_rera_id, ->(rera_id) { where(rera_id: rera_id) }
  scope :filter_by_status, ->(status) { where(status: status) }
  scope :filter_by_city, ->(city) { where(city: city) }
  scope :filter_by__id, ->(_id) { where(_id: _id) }
  scope :filter_by_search, ->(search) { regex = ::Regexp.new(::Regexp.escape(search), 'i'); where({ '$and' => ["$or": [{first_name: regex}, {last_name: regex}, {email: regex}, {phone: regex}] ] }) }

  default_scope -> { desc(:created_at) }

  enable_audit(
    audit_fields: %i[title rera_id status gstin_number aadhaar],
    reference_ids_without_associations: [
      { field: 'associated_user_id', klass: 'User' }
    ]
  )

  belongs_to :associated_user, class_name: 'User', optional: true
  belongs_to :manager, class_name: 'User', optional: true
  has_many :users
  has_one :address, as: :addressable
  has_one :bank_detail, as: :bankable, validate: false
  has_many :assets, as: :assetable

  validates *SHORT_FORM, presence: true
  validates *FULL_FORM, presence: true, on: :submit_for_approval
  validates :pan_number, presence: true, unless: :nri?, on: :submit_for_approval
  validates :rera_id, presence: true, if: :rera_applicable?
  validates :gstin_number, presence: true, if: :gst_applicable?
  validates :team_size, :numericality => { :greater_than => 0 }, allow_blank: true
  validates :status_change_reason, presence: true, if: proc { |cp| cp.status == 'rejected' }
  validates :aadhaar, format: { with: /\A\d{12}\z/i, message: 'is not a valid aadhaar number' }, allow_blank: true
  validates :rera_id, uniqueness: true, allow_blank: true
  validates :phone, uniqueness: true, phone: { possible: true, types: %i[voip personal_number fixed_or_mobile] }, allow_blank: true
  validates :email, uniqueness: true, allow_blank: true
  validates :status, inclusion: { in: proc { ChannelPartner::STATUS } }
  validates :company_type, inclusion: { in: proc { ChannelPartner::COMPANY_TYPE } }, allow_blank: true
  validates :source, inclusion: { in: proc { ChannelPartner::SOURCE } }, allow_blank: true
  validates :category, inclusion: { in: proc { ChannelPartner::CATEGORY } }, allow_blank: true
  validates :region, inclusion: { in: proc { ChannelPartner::REGION } }, allow_blank: true

  validates :pan_number, :aadhaar, uniqueness: true, allow_blank: true
  validates :pan_number, format: { with: /[a-z]{3}[cphfatblj][a-z]\d{4}[a-z]/i, message: 'is not in a format of AAAAA9999A' }, allow_blank: true
  #validates :first_name, :last_name, name: true, allow_blank: true
  validates :erp_id, uniqueness: true, allow_blank: true
  validate :user_based_uniqueness

  validates :experience, inclusion: { in: proc{ ChannelPartner::EXPERIENCE } }, allow_blank: true
  validates :expertise, array: { inclusion: {allow_blank: true, in: ChannelPartner::EXPERTISE } }
  validates :address, copy_errors_from_child: true, allow_blank: true

  validates :gstin_number, format: { with: /\A([0]{1}[1-9]{1}|[1-2]{1}[0-9]{1}|[3]{1}[0-7]{1})([a-zA-Z]{5}[0-9]{4}[a-zA-Z]{1}[1-9a-zA-Z]{1}[zZ]{1}[0-9a-zA-Z]{1})+\z/i, message: 'is not valid format' }, allow_blank: true
  validates :rera_id, format: { with: /\A([A-Za-z])\d{11}\z/i, message: 'is not valid format' }, allow_blank: true

  accepts_nested_attributes_for :bank_detail, :address

  delegate :name, :role, :role?, :email, to: :manager, prefix: true, allow_nil: true

  def self.available_statuses
    [
      { id: 'active', text: 'Active' },
      { id: 'inactive', text: 'Inactive' },
      { id: 'pending', text: 'Pending Approval' },
      { id: 'rejected', text: 'Rejected Request' }
    ]
  end

  def name
    str = "#{title} #{first_name} #{last_name}"
    str += " (#{company_name})" if company_name.present?
    str
  end

  alias :resource_name :name

  def ds_name
    "#{name} - #{email} - #{phone}"
  end

  def sfdc_phone
    self.phone.gsub(/\A\+91/, '')
  end

  # As we want to push channel partner once its activated, we are using erp_model with create event here.
  def update_details
    sync_log = SyncLog.new
    @erp_models = ErpModel.where(resource_class: self.class, action_name: 'create', is_active: true)
    @erp_models.each do |erp|
      sync_log.sync(erp, self)
    end
  end

  def sync(erp_model, sync_log)
    Api::ChannelPartnerDetailsSync.new(erp_model, self, sync_log).execute
  end

  def update_erp_id(erp_id, domain)
    super
    associated_user.update_erp_id(erp_id, domain) if associated_user
  end

  def doc_types
    doc_types = self.nri? ? %w[cheque_scanned_copy company_incorporation_certificate form_10f tax_residency_certificate pe_declaration] : %w[pan_card cheque_scanned_copy]
    doc_types << 'rera_certificate' if self.rera_applicable?
    doc_types << 'gst_certificate' if self.gst_applicable?
    doc_types
  end

  private
  def user_based_uniqueness
    query = []
    query << { phone: phone } if phone.present?
    query << { email: email } if email.present?
    query << { rera_id: rera_id } if rera_id.present?
    criteria = User.or(query)
    criteria = criteria.ne(id: associated_user_id) if associated_user_id.present?
    if criteria.present?
      errors.add :base, 'User with phone, email or rera already exists'
    end
  end

  # Class methods
  class << self

    def user_based_scope(user, _params = {})
      custom_scope = {}
      #if user.role?('cp_admin')
      #  cp_ids = User.where(manager_id: user.id).distinct(:id)
      #  custom_scope = { manager_id: {"$in": cp_ids} }
      #elsif user.role?('cp')
      #  custom_scope = { manager_id: user.id }
      #end
      #custom_scope
    end

  end # end class methods
end
