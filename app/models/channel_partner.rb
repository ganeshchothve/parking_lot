class ChannelPartner
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable

  field :name, type: String
  field :email, type: String
  field :phone, type: String
  field :rera_id, type: String
  field :location, type: String
  field :associated_user_id, type: BSON::ObjectId
  field :status, type: String, default: 'active'
  field :title, type: String
  field :first_name, type: String
  field :last_name, type: String
  field :street, type: String
  field :house_number, type: String
  field :city, type: String
  field :postal_code, type: String
  field :country, type: String
  field :mobile_phone, type: String
  field :company_name, type: String
  field :pan_no, type: String
  field :gstin_no, type: String
  field :bank_name, type: String
  field :bank_beneficiary_account_no, type: String
  field :bank_account_type, type: String
  field :bank_address, type: String
  field :bank_city, type: String
  field :bank_postal_Code, type: String
  field :bank_region, type: String
  field :bank_country, type: String
  field :bank_ifsc_code, type: String
  field :region, type: String
  field :aadhaar_no, type: String

  mount_uploader :pan_card_doc, DocUploader
  mount_uploader :bank_check_doc, DocUploader
  mount_uploader :aadhaar_card_doc, DocUploader

  validates :name, :email, :phone, :rera_id, :location, :status, presence: true
  validates :phone, uniqueness: true#, phone: true # TODO: we can remove phone validation, as the validation happens in sell.do
  validates :email, :rera_id, uniqueness: true, allow_blank: true
  validates :status, inclusion: {in: Proc.new{ ChannelPartner.available_statuses.collect{|x| x[:id]} } }
  validate :user_level_uniqueness
  validate :cannot_make_inactive


  validates :name, :last_name, :city, format: { with: /\A[a-zA-Z]*\z/}
  validates :postal_code, format: { with: /\A[0-9]*\z/}
  validates :region, format: { with: /\A[a-zA-Z ]*\z/}

  # validates :city, format: { with: /\A[a-zA-Z]*\z/}
  # validates :city,  format: { with: /[a-zA-Z]/}
  # validates :postal_code, format: { with: /[0-9]/}
  # validates :mobile_phone, format: { with: /\A\d+\z/ }
  # validates :email, :presence => true, :format => { with: /\([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i }
  # validates :mobile_phone, :presence => true, :uniqueness => true#, :min => 10, :max => 15
  # validates :pan_no, format: { with: /[a-zA-Z0-9]/} #, :minimum => 10
  # validates :bank_beneficiary_account_no, format: { with: /[0-9]/}
  # EMAIL_REGEX = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i




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
      if params[:fltrs][:location].present?
        selector[:location] = params[:fltrs][:location]
      end
    end
    or_selector = {}
    if params[:q].present?
      regex = ::Regexp.new(::Regexp.escape(params[:q]), 'i')
      or_selector = {"$or": [{name: regex}, {email: regex}, {phone: regex}] }
    end
    self.where(selector).where(or_selector)
  end

  def ds_name
    "#{name} - #{email} - #{phone}"
  end

def channel_partner_json
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
