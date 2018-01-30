class UserKyc
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable

  field :name, type: String
  field :email, type: String
  field :phone, type: String
  field :dob, type: Date
  field :pan_number,type: String

  field :aadhaar,type: String
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

  validates :name, :email, :phone, :dob, :pan_number, presence: false
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
end
