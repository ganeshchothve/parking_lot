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
  field :aadhaar,type: String
  field :oci,type: String
  field :gstn, type: String
  field :is_company, type: Boolean
  field :anniversary, type: Date
  field :nri, type: Boolean
  field :poa, type: Boolean
  field :poa_details, type: String
  field :company_name, type: String
  field :existing_customer, type: Boolean
  field :existing_customer_name, type: String
  field :existing_customer_project, type: String
  field :comments, type: String

  field :education_qualification, type: String
  field :designation, type: String
  field :customer_company_name, type: String
  field :poa_details_phone_no, type: String

  has_many :assets, as: :assetable
  has_one :bank_detail
  belongs_to :user
  belongs_to :creator, class_name: 'User'
  has_and_belongs_to_many :project_units
  has_and_belongs_to_many :booking_details

  validates :first_name, :last_name, :email, :phone, :dob, presence: false
  # validates :poa, inclusion: {in: [true]}, if: Proc.new{ |kyc| kyc.nri? }
  validates :pan_number, presence: true, unless: Proc.new{ |kyc| kyc.nri? }
  validates :oci, presence: true, if: Proc.new{ |kyc| kyc.nri? }
  validates :email, uniqueness: {scope: :user_id}, allow_blank: true
  validates :pan_number, uniqueness: {scope: :user_id}, allow_blank: true
  validates :phone, uniqueness: {scope: :user_id}, phone: true # TODO: we can remove phone validation, as the validation happens in
  validates :pan_number, format: {with: /[a-z]{3}[cphfatblj][a-z]\d{4}[a-z]/i, message: 'is not in a format of AAAAA9999A'}, allow_blank: true
  validates :aadhaar, format: {with: /\A\d{12}\z/i, message: 'is not a valid aadhaar number'}, allow_blank: true
  validates :company_name, :gstn, presence: true, if: Proc.new{|kyc| kyc.is_company?}
  validates :poa_details, presence: true, if: Proc.new{|kyc| kyc.poa?}
  validates :existing_customer_name, :existing_customer_project, presence: true, if: Proc.new{|kyc| kyc.existing_customer?}
  validates :salutation, inclusion: {in: Proc.new{ UserKyc.available_salutations.collect{|x| x[:id]} } }

  def self.available_salutations
    [
      {id: "Mr.", text: 'Mr.'},
      {id: "Mrs.", text: 'Mrs.'},
      {id: "Ms.", text: 'Ms.'},
      {id: "Brig.", text: 'Brig.'},
      {id: "Captain", text: 'Captain'},
      {id: "Col", text: 'Col'},
      {id: "Dr.", text: 'Dr.'},
      {id: "Maharaj", text: 'Maharaj'},
      {id: "Prof.", text: 'Prof.'}
    ]
  end

  def name
    "#{UserKyc.available_salutations.find{|x| x[:id] == salutation}[:text] rescue '' } #{first_name} #{last_name}"
  end

  def api_json
    # extract phone and country code from phone field
    phone = Phonelib.parse(kyc.phone)
    country_code = phone.country_code
    kyc_phone = phone.national(false).sub(/^0/, "")

    hash = {
      applicant_id: kyc.id.to_s,
      salutation: kyc.salutation,
      first_name: kyc.first_name,
      last_name: kyc.last_name,
      email: kyc.email,
      country_code_primary_phone: country_code,
      phone: kyc_phone,
      pan_no: kyc.pan_number,
      dob: (kyc.dob.strftime("%Y-%m-%d") rescue nil),
      anniversary: (kyc.anniversary.strftime("%Y-%m-%d") rescue nil),
      nri: kyc.nri ? "NRI" : "Indian",
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
end
