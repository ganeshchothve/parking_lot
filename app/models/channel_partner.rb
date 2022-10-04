class ChannelPartner
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include CrmIntegration
  extend FilterByCriteria
  include ChannelPartnerStateMachine
  include ApplicationHelper
  extend ApplicationHelper
  extend DocumentsConcern

  STATUS = %w(active inactive pending rejected)
  THIRD_PARTY_REFERENCE_IDS = %w(reference_id)
  EXPERTISE = %w( rentals retail residential commercial )
  EXPERIENCE = ['0-1 yrs', '1-5 yrs', '5-10 yrs', '10-15 yrs', '15-20 yrs', '20+ yrs']
  DEVELOPERS = [ "Godrej Properties", "Hiranandani", "Lodha Group", "Piramal Realty", "Kanakia", "Mahindra Lifespaces developers", "Kalpataru", "Runwal Group", "Dosti Group", "Wadhwa Group", "Rustomjee", "Puraniks builders", "Adhiraj construction", "L & T Realty", "Arkade Group", "Paradise group", "Chandak", "Marathon Realty", "Raymond Realty", "Damji Shamji Shah", "Shapoorji Pallonji Real Estate", "SD Corp", "Ornate Universal", "Sethia Infrastructure", "Aadi Properties", "Raheja construction", "Tata Housing", "Ajmera", "Adani", "Oberoi Realty", "Acme", "K Raheja", "Hubtown", "Ekta world", "Akshar group", "Raunak group", "JP Infra", "Sunteck Realty Ltd", "Seth Developers", "Kabra developer", "Koltepatil developer" ]
  SERVICES = [ "Work on Mandates", "Sales Training & Branded Collaterals", "Lead Generation Help", "CRM" ]

  # Add different types of documents which are uploaded on channel_partner
  DOCUMENT_TYPES = %w[pan_card rera_certificate gst_certificate cheque_scanned_copy company_incorporation_certificate form_10f tax_residency_certificate pe_declaration]
  COMPANY_TYPE = ['Sole Proprietorship', 'Partnership', 'Private Limited', 'Public Limited', 'Others']
  CATEGORY = ['CP Company', 'Individual CP', 'ROTN', 'IRDA', 'Chartered accountants', 'IT Profession']
  SOURCE = ['Internal CP', 'External CP']
  INTERNAL_CATEGORY = ['cat_a', 'cat_b', 'cat_c']
  SHORT_FORM = %i(company_name rera_applicable status)
  FULL_FORM = SHORT_FORM.clone + %i(gst_applicable nri) #manager_id)

  attr_accessor :first_name, :last_name, :email, :phone, :referral_code, :is_existing_company

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
  field :internal_category, type: String
  field :source, type: String
  field :website, type: String
  field :city, type: String
  field :regions, type: Array, default: []
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

  # Tracking selldo srd for new channel partner registrations.
  field :srd, type: String
  field :cp_code, type: String

  scope :filter_by_rera_id, ->(rera_id) { where(rera_id: rera_id) }
  scope :filter_by_manager_id, ->(manager_id) { where(manager_id: manager_id) }
  scope :filter_by_status, ->(status) { where(status: status) }
  scope :filter_by_internal_category, ->(internal_category) { where(internal_category: internal_category) }
  scope :filter_by_city, ->(city) { where(city: city) }
  scope :filter_by_regions, ->(regions) { where( regions: { "$all": regions }) }
  scope :filter_by__id, ->(_id) { where(_id: _id) }
  scope :filter_by_search, ->(search) { regex = ::Regexp.new(::Regexp.escape(search), 'i'); where(company_name: regex) }
  scope :filter_by_created_at, ->(date) { start_date, end_date = date.split(' - '); where(created_at: (Date.parse(start_date).beginning_of_day)..(Date.parse(end_date).end_of_day)) }
  scope :filter_by_booking_portal_client_id, ->(booking_portal_client_id) { where(booking_portal_client_id: booking_portal_client_id) }

  default_scope -> { desc(:created_at) }

  enable_audit(
    audit_fields: %i[title rera_id status gstin_number aadhaar],
    reference_ids_without_associations: [
      { field: 'associated_user_id', klass: 'User' }
    ]
  )

  belongs_to :booking_portal_client, class_name: 'Client'
  belongs_to :manager, class_name: 'User', optional: true
  belongs_to :primary_user, class_name: 'User'
  has_many :users
  has_one :address, as: :addressable
  has_one :bank_detail, as: :bankable, validate: false
  has_many :assets, as: :assetable
  has_many :site_visits

  mount_uploader :company_logo, DocUploader

  #validates :first_name, presence: true, on: :create
  validates *SHORT_FORM, presence: true
  validates *FULL_FORM, presence: true, on: :submit_for_approval
  #validate :phone_or_email_required, if: proc { |cp| cp.phone.blank? && cp.email.blank? }, on: :create
  #
  #TODO: Commented for testing on Mobile app
  #validates :pan_number, presence: true, unless: :nri?, on: :submit_for_approval
  #validates :email, uniqueness: true, allow_blank: true
  #validates :first_name, :last_name, name: true, allow_blank: true
  #validates :rera_id, format: { with: /\A([A-Za-z])\d{11}\z/i, message: 'is not valid format' }, allow_blank: true
  #validate :docs_required_for_approval, on: :submit_for_approval

  validates :rera_id, presence: true, uniqueness: true, length: { minimum: 6 }, format: { with: /\A[0-9a-zA-Z\/]*\z/i, message: 'allows only aplabets, numbers & forward slash(/)' }
  validates :gstin_number, presence: true, if: :gst_applicable?
  validates :team_size, :numericality => { :greater_than => 0 }, allow_blank: true
  validates :status_change_reason, presence: true, if: proc { |cp| cp.status == 'rejected' }
  validates :aadhaar, format: { with: /\A\d{12}\z/i, message: 'is not a valid aadhaar number' }, allow_blank: true
  validates :phone, phone: { possible: true, types: %i[voip personal_number fixed_or_mobile] }, allow_blank: true
  validates :status, inclusion: { in: proc { ChannelPartner::STATUS } }
  validates :company_type, inclusion: { in: proc { ChannelPartner::COMPANY_TYPE } }, allow_blank: true
  validates :source, inclusion: { in: proc { ChannelPartner::SOURCE } }, allow_blank: true
  validates :category, inclusion: { in: proc { ChannelPartner::CATEGORY } }, allow_blank: true
  validates :internal_category, inclusion: { in: proc { ChannelPartner::INTERNAL_CATEGORY } }, allow_blank: true
  # validates :city, inclusion: { in: self.booking_portal_client.present? ? self.booking_portal_client.regions.distinct(:city) : [] }, allow_blank: true
  # validates :regions, array: { inclusion: { allow_blank: true, in: ((self.booking_portal_client.present? && self.booking_portal_client.regions.present?) ? (self.booking_portal_client.regions.distinct(:partner_regions).flatten || []) : []) } }
  validates :company_name, uniqueness: true
  validates :pan_number, :aadhaar, uniqueness: true, allow_blank: true
  validates :pan_number, format: { with: /[a-z]{3}[cphfatblj][a-z]\d{4}[a-z]/i, message: 'is not in a format of AAAAA9999A' }, allow_blank: true
  validates :erp_id, uniqueness: true, allow_blank: true
  validate :user_based_uniqueness
  validates :primary_user_id, uniqueness: true, allow_blank: true
  validates :cp_code, uniqueness: true, allow_blank: true

  validates :experience, inclusion: { in: proc{ ChannelPartner::EXPERIENCE } }, allow_blank: true
  validates :expertise, array: { inclusion: {allow_blank: true, in: ChannelPartner::EXPERTISE } }
  validates :address, copy_errors_from_child: true, allow_blank: true

  validates :gstin_number, format: { with: /\A([0]{1}[1-9]{1}|[1-2]{1}[0-9]{1}|[3]{1}[0-7]{1})([a-zA-Z]{5}[0-9]{4}[a-zA-Z]{1}[1-9a-zA-Z]{1}[zZ]{1}[0-9a-zA-Z]{1})+\z/i, message: 'is not valid format' }, allow_blank: true

  accepts_nested_attributes_for :bank_detail, :address

  delegate :name, :role, :role?, :email, to: :manager, prefix: true, allow_nil: true

  def phone_or_email_required
    errors.add(:base, 'Email or Phone is required')
  end

  def name
    company_name
  end

  alias :resource_name :name

  def ds_name
    str = name
    str += " - #{rera_id}" if rera_applicable?
    str += " - #{email}" if email.present? 
    str
  end

  #def sfdc_phone
  #  self.phone.gsub(/\A\+91/, '')
  #end

  def doc_types
    doc_types = self.nri? ? %w[company_incorporation_certificate form_10f tax_residency_certificate pe_declaration] : %w[pan_card]
    doc_types << 'rera_certificate' if self.rera_applicable?
    doc_types << 'gst_certificate' if self.gst_applicable?
    doc_types
  end

  def docs_required_for_approval
    docs_required = []
    self.doc_types.each do |dt|
      docs_required << dt unless self.assets.where(document_type: dt).present?
    end
    if docs_required.present?
      docs_msg = docs_required.collect {|x| I18n.t("mongoid.attributes.channel_partner/file_types.#{x}")}.to_sentence
      self.errors.add(:base, "Please upload #{docs_msg}")
    end
  end

  private
  def user_based_uniqueness
    if email.present? && User.where(email: email).present?
      errors.add :base, 'Email is already taken'
    end
  end

  # Class methods
  class << self

    def user_based_scope(user, _params = {})
      custom_scope = {}
      if user.present?
        if user.role?('cp_admin')
         #cp_ids = User.where(manager_id: user.id).distinct(:id)
         #custom_scope = { manager_id: {"$in": cp_ids} }
        elsif user.role?('cp')
         custom_scope = { manager_id: user.id }
        elsif user.role.in?(%w(cp_owner channel_partner))
          custom_scope = { id: user.channel_partner_id }
        elsif user.role.in?(%w(admin sales))
          custom_scope = { booking_portal_client_id: user.booking_portal_client.id }
        elsif user.role.in?(%w(superadmin))
          custom_scope = { booking_portal_client_id: user.selected_client_id }
        end
      end
      custom_scope
    end

  end # end class methods
end
