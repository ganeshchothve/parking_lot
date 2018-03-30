class UserKyc
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable

  field :salutation, type: String
  field :first_name, type: String
  field :last_name, type: String
  field :email, type: String
  field :phone, type: String
  field :dob, type: Date
  field :pan_number,type: String

  field :street, type: String
  field :house_number, type: String
  field :city, type: String
  field :postal_code, type: String
  field :state, type: String
  field :country, type: String

  mount_uploader :photo, DocUploader
  mount_uploader :pancard_photo, DocUploader
  mount_uploader :adharcard_photo, DocUploader
  mount_uploader :address_proof, DocUploader

  field :aadhaar,type: String
  field :oci,type: String
  field :gstn, type: String
  field :is_company, type: Boolean
  field :anniversary, type: Date
  field :nri, type: Boolean
  field :poa, type: Boolean
  field :poa_details, type: String
  field :company_name, type: String
  field :loan_required, type: Boolean
  field :bank_name, type: String
  field :existing_customer, type: Boolean
  field :existing_customer_name, type: String
  field :existing_customer_project, type: String
  field :comments, type: String

  belongs_to :user
  belongs_to :creator, class_name: 'User'
  has_and_belongs_to_many :project_units
  has_and_belongs_to_many :booking_details

  validates :first_name, :last_name, :email, :phone, :dob, :pan_number, :city, :state, :country, :street, presence: false
  validates :poa, inclusion: {in: [true]}, if: Proc.new{ |kyc| kyc.nri? }
  validates :email, uniqueness: true, allow_blank: true
  validates :pan_number, uniqueness: true, allow_blank: true
  validates :phone, uniqueness: true, phone: true # TODO: we can remove phone validation, as the validation happens in
  validates :pan_number, format: {with: /[a-z]{3}[cphfatblj][a-z]\d{4}[a-z]/i, message: 'is not in a format of AAAAA9999A'}
  validates :aadhaar, format: {with: /\A\d{12}\z/i, message: 'is not a valid aadhaar number'}, allow_blank: true
  validates :company_name, :gstn, presence: true, if: Proc.new{|kyc| kyc.is_company?}
  validates :poa_details, presence: true, if: Proc.new{|kyc| kyc.poa?}
  validates :bank_name, presence: true, if: Proc.new{|kyc| kyc.loan_required?}
  validates :existing_customer_name, :existing_customer_project, presence: true, if: Proc.new{|kyc| kyc.existing_customer?}
  validates :salutation, inclusion: {in: Proc.new{ UserKyc.available_salutations.collect{|x| x[:id]} } }

  def self.available_salutations
    [
      {id: "Brig.", text: 'Brig.'},
      {id: "Captain", text: 'Captain'},
      {id: "Col", text: 'Col'},
      {id: "Dr.", text: 'Dr.'},
      {id: "Maharaj", text: 'Maharaj'},
      {id: "Mr.", text: 'Mr.'},
      {id: "Mrs.", text: 'Mrs.'},
      {id: "Ms.", text: 'Ms.'},
      {id: "Prof.", text: 'Prof.'}
    ]
  end

  def name
    "#{UserKyc.available_salutations.find{|x| x[:id] == salutation}[:text] rescue '' } #{first_name} #{last_name}"
  end
end
