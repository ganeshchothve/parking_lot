class ChannelPartner
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include SyncDetails

  field :title, type: String
  field :first_name, type: String
  field :last_name, type: String
  field :email, type: String
  field :phone, type: String
  field :rera_id, type: String
  field :status, type: String, default: 'inactive'

  field :company_name, type: String
  field :pan_number, type: String
  field :gstin_number, type: String
  field :aadhaar, type: String

  field :erp_id, type: String, default: ''

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
  has_one :address, as: :addressable, validate: false
  has_one :bank_detail, as: :bankable, validate: false
  has_many :assets, as: :assetable
  has_many :sync_logs, as: :resource

  validates :first_name, :last_name, :rera_id, :status, :aadhaar, presence: true
  validates :aadhaar, format: { with: /\A\d{12}\z/i, message: 'is not a valid aadhaar number' }, allow_blank: true
  validates :rera_id, uniqueness: true, allow_blank: true
  validates :phone, uniqueness: true, phone: { possible: true, types: %i[voip personal_number fixed_or_mobile] }, if: proc { |user| user.email.blank? }
  validates :email, uniqueness: true, if: proc { |user| user.phone.blank? }
  validates :status, inclusion: { in: proc { ChannelPartner.available_statuses.collect { |x| x[:id] } } }
  validates :pan_number, :aadhaar, uniqueness: true, allow_blank: true
  validates :pan_number, format: { with: /[a-z]{3}[cphfatblj][a-z]\d{4}[a-z]/i, message: 'is not in a format of AAAAA9999A' }, allow_blank: true
  validate :cannot_make_inactive
  validates :first_name, :last_name, format: { with: /\A[a-zA-Z]*\z/ }
  validates :erp_id, uniqueness: true, allow_blank: true
  validate :user_based_uniqueness

  accepts_nested_attributes_for :bank_detail, :address

  def self.available_statuses
    [
      { id: 'active', text: 'Active' },
      { id: 'inactive', text: 'Inactive' }
    ]
  end

  def self.build_criteria(params = {})
    selector = {}
    if params[:fltrs].present?
      if params[:fltrs][:rera_id].present?
        selector[:rera_id] = params[:fltrs][:rera_id]
      end
      if params[:fltrs][:status].present?
        selector[:status] = params[:fltrs][:status]
      end
      selector[:city] = params[:fltrs][:city] if params[:fltrs][:city].present?
    end
    or_selector = {}
    if params[:search].present?
      regex = ::Regexp.new(::Regexp.escape(params[:search]), 'i')
      or_selector = {"$or": [{first_name: regex}, {last_name: regex}, {email: regex}, {phone: regex}] }
    end
    if params[:fltrs].present? && params[:fltrs][:_id].present?
      where(id: params[:fltrs][:_id])
    else
      self.and([selector, or_selector])
    end
  end

  def name
    str = "#{title} #{first_name} #{last_name}"
    str += " (#{company_name})" if company_name.present?
    str
  end

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
    if status == 'active'
      _erp_models = if erp_id.blank?
        ErpModel.where(resource_class: self.class, action_name: 'create')
      else
        ErpModel.where(resource_class: self.class, action_name: 'update')
      end
      _erp_models.each do |erp|
        Api::ChannelPartnerDetailsSync.new(erp, self, sync_log).execute
      end
    end
  end

  def update_erp_id(erp_id)
    associated_user.try(:set, {erp_id: erp_id})
    set(erp_id: erp_id)
  end

  private

  def cannot_make_inactive
    if status_changed? && status == 'inactive' && persisted?
      errors.add :status, 'cannot be reverted to "inactive" once activated'
    end
  end

  def user_based_uniqueness
    query = []
    query << { phone: phone } if phone.present?
    query << { email: email } if email.present?
    query << { rera_id: rera_id } if rera_id.present?
    criteria = User.or(query)
    criteria = criteria.ne(id: associated_user_id) if associated_user_id.present?
    if criteria.present?
      errors.add :base, 'We have a user with similar details already registered'
    end
  end
end
