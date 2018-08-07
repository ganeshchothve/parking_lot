class ChannelPartner
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable

  field :title, type: String
  field :first_name, type: String
  field :last_name, type: String
  field :email, type: String
  field :phone, type: String
  field :rera_id, type: String
  field :associated_user_id, type: BSON::ObjectId
  field :status, type: String, default: "inactive"

  field :company_name, type: String
  field :pan_number, type: String
  field :gstin_number, type: String
  field :aadhaar, type: String

  enable_audit({
    audit_fields: [:title, :rera_id, :status, :gstin_number, :aadhaar],
    reference_ids_without_associations: [
      {field: 'associated_user_id', klass: 'User'},
    ]
  })

  has_one :address, as: :addressable, validate: false
  has_one :bank_detail, as: :bankable, validate: false
  has_many :assets, as: :assetable

  validates :first_name, :last_name, :email, :phone, :rera_id, :status, :aadhaar, presence: true
  validates :aadhaar, format: {with: /\A\d{12}\z/i, message: 'is not a valid aadhaar number'}, allow_blank: true
  validates :phone, uniqueness: true, phone: true
  validates :email, :rera_id, uniqueness: true, allow_blank: true
  validates :status, inclusion: {in: Proc.new{ ChannelPartner.available_statuses.collect{|x| x[:id]} } }
  validates :pan_number, :aadhaar, uniqueness: true, allow_blank: true
  validates :pan_number, format: {with: /[a-z]{3}[cphfatblj][a-z]\d{4}[a-z]/i, message: 'is not in a format of AAAAA9999A'}, allow_blank: true
  validate :user_level_uniqueness
  validate :cannot_make_inactive
  validates :first_name, :last_name, format: { with: /\A[a-zA-Z]*\z/}

  accepts_nested_attributes_for :bank_detail, :address

  def self.available_statuses
    [
      {id: 'active', text: 'Active'},
      {id: 'inactive', text: 'Inactive'}
    ]
  end

  def associated_user
    if self.associated_user_id.present?
      return User.find(self.associated_user_id)
    else
      return nil
    end
  end

  def self.build_criteria params={}
    selector = {}
    if params[:fltrs].present?
      if params[:fltrs][:rera_id].present?
        selector[:rera_id] = params[:fltrs][:rera_id]
      end
      if params[:fltrs][:status].present?
        selector[:status] = params[:fltrs][:status]
      end
      if params[:fltrs][:city].present?
        selector[:city] = params[:fltrs][:city]
      end
    end
    or_selector = {}
    if params[:q].present?
      regex = ::Regexp.new(::Regexp.escape(params[:q]), 'i')
      or_selector = {"$or": [{first_name: regex}, {last_name: regex}, {email: regex}, {phone: regex}] }
    end
    self.where(selector).where(or_selector)
  end

  def name
    str = "#{title} #{first_name} #{last_name}"
    if company_name.present?
      str += " (#{company_name})"
    end
  end

  def ds_name
    "#{name} - #{email} - #{phone}"
  end

  private
  def user_level_uniqueness
    if self.new_record? || (self.status_changed? && self.status == 'active')
      user = User.or([{email: self.email}, {phone: self.phone}]).first
      if user.present? && user.id != self.associated_user_id
        self.errors.add :base, "Email or Phone has already been taken"
      end
    end
  end

  def cannot_make_inactive
    if self.status_changed? && self.status == 'inactive' && self.persisted?
      self.errors.add :status, ' cannot be reverted to "inactive" once activated'
    end
  end
end
