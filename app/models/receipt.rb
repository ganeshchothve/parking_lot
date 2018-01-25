class Receipt
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include Mongoid::Autoinc

  field :receipt_id, type: String
  field :payment_mode, type: String, default: 'online'
  field :issued_date, type: Date # Date when cheque / DD etc are issued
  field :issuing_bank, type: String # Bank which issued cheque / DD etc
  field :issuing_bank_branch, type: String # Branch of bank
  field :payment_identifier, type: String # cheque / DD number / online transaction reference from gateway
  field :tracking_id, type: String
  field :total_amount, type: Float, default: 0 # Total amount
  field :status, type: String, default: 'pending' # pending, success, failure, clearance_pending
  field :status_message, type: String
  field :payment_type, type: String, default: 'blocking' # blocking, booking
  field :reference_project_unit_id, type: BSON::ObjectId # the channel partner or admin can choose this, but its not binding on the user to choose this reference unit

  belongs_to :user, optional: true
  belongs_to :project_unit, optional: true
  belongs_to :creator, class_name: 'User'

  validates :receipt_id, :total_amount, :status, :payment_mode, :payment_type, :user_id, presence: true
  validates :payment_identifier, presence: true, if: Proc.new{|receipt| receipt.payment_type == 'online' && receipt.status != 'pending' }
  validates :project_unit_id, presence: true, if: Proc.new{|receipt| receipt.payment_type != 'blocking'} # allow the user to make a blocking payment without any unit
  validates :status, inclusion: {in: Proc.new{ Receipt.available_statuses.collect{|x| x[:id]} } }
  validates :payment_type, inclusion: {in: Proc.new{ Receipt.available_payment_types.collect{|x| x[:id]} } }
  validates :payment_mode, inclusion: {in: Proc.new{ Receipt.available_payment_modes.collect{|x| x[:id]} } }
  validates :reference_project_unit_id, presence: true, if: Proc.new{ |receipt| receipt.creator.role != 'user' }
  validate :validate_total_amount
  validates :issued_date, :issuing_bank, :issuing_bank_branch, :payment_identifier, presence: true, if: Proc.new{|receipt| receipt.payment_mode != 'online' }
  validate :status_changed

  increments :order_id
  default_scope -> {desc(:created_at)}

  def reference_project_unit
    if self.reference_project_unit_id.present?
      ProjectUnit.find(self.reference_project_unit_id)
    else
      nil
    end
  end

  def self.available_statuses
    [
      {id: 'pending', text: 'Pending'},
      {id: 'success', text: 'Success'},
      {id: 'clearance_pending', text: 'Pending Clearance'},
      {id: 'failed', text: 'Failed'}
    ]
  end

  def self.available_payment_modes
    [
      {id: 'online', text: 'Online'},
      {id: 'cheque', text: 'Cheque'},
      {id: 'rtgs', text: 'RTGS'},
      {id: 'neft', text: 'NEFT'}
    ]
  end

  def self.available_payment_types
    [
      {id: 'blocking', text: 'Blocking'},
      {id: 'booking', text: 'Booking'}
    ]
  end

  def build_for_hdfc
    payload = ""
    payload += "merchant_id=#{PAYMENT_PROFILE[:CCAVENUE][:merchantid]}&" 
    payload += "amount="+self.total_amount.to_s+"&" 
    payload += "order_id="+self.order_id.to_s+"&" 
    payload += "currency=INR&" 
    payload += "language=EN&"
    if Rails.env.production?
      payload += "redirect_url=http://www.embassyindia.com/payment/hdfc/process_payment/success&"
      payload += "cancel_url=http://www.embassyindia.com/payment/hdfc/process_payment/failure"
    else
      payload += "redirect_url=http://embassysprings2.amura.in//payment/hdfc/process_payment/success&"
      payload += "cancel_url=http://embassysprings2.amura.in/payment/hdfc/process_payment/failure"
    end
    crypto = Crypto.new
    encrypted_data = crypto.encrypt(payload,PAYMENT_PROFILE[:CCAVENUE][:working_key])
    return encrypted_data
  end

  def handle_response_for_hdfc(encResponse)
    crypto = Receipt::Crypto.new
    decResp = crypto.decrypt(encResponse,PAYMENT_PROFILE[:CCAVENUE][:working_key])
    decResp = decResp.split("&") rescue []
    decResp.each do |key|
      if key.from(0).to(key.index("=")-1)=='order_status'
          self.status = key.from(key.index("=")+1).to(-1).downcase
          if(self.status == "failure")
            self.status = "failed"
          end
      end
      if key.from(0).to(key.index("=")-1)=='tracking_id'
        self.tracking_id = key.from(key.index("=")+1).to(-1)
      end
      if key.from(0).to(key.index("=")-1)=='bank_ref_no'
        self.payment_identifier = key.from(key.index("=")+1).to(-1)
      end
      if key.from(0).to(key.index("=")-1)=='failure_message'
        self.status_message = key.from(key.index("=")+1).to(-1).downcase 
      end  
      if key.from(0).to(key.index("=")-1)=='order_id'
        self.id.to_s == key.from(key.index("=")+1).to(-1)
      end
    end
    self.save(validate: false)
  end

  class Crypto
    INIT_VECTOR = (0..15).to_a.pack("C*")    
    def encrypt(plain_text, key)
        secret_key =  [Digest::MD5.hexdigest(key)].pack("H*") 
        cipher = OpenSSL::Cipher::Cipher.new('aes-128-cbc')
        cipher.encrypt
        cipher.key = secret_key
        cipher.iv  = INIT_VECTOR
        encrypted_text = cipher.update(plain_text) + cipher.final
        return (encrypted_text.unpack("H*")).first
    end
    def decrypt(cipher_text,key)
        secret_key =  [Digest::MD5.hexdigest(key)].pack("H*")
        encrypted_text = [cipher_text].pack("H*")
        decipher = OpenSSL::Cipher::Cipher.new('aes-128-cbc')
        decipher.decrypt
        decipher.key = secret_key
        decipher.iv  = INIT_VECTOR
        decrypted_text = (decipher.update(encrypted_text) + decipher.final).gsub(/\0+$/, '')
        return decrypted_text
    end
  end
  
  private
  def validate_total_amount
    if self.total_amount < ProjectUnit.blocking_amount && self.project_unit_id.blank? && self.new_record?
      self.errors.add :total_amount, " cannot be less than or equal to #{ProjectUnit.blocking_amount}"
    end
    if self.total_amount <= 0
      self.errors.add :total_amount, " cannot be less than or equal to 0"
    end
    if self.project_unit_id.present? && (self.total_amount > self.project_unit.pending_balance) && self.new_record?
      self.errors.add :total_amount, " cannot be greater than #{self.project_unit.pending_balance}"
    end
    if self.reference_project_unit_id.present? && (self.total_amount > self.reference_project_unit.pending_balance({user_id: self.user_id})) && self.new_record?
      self.errors.add :total_amount, " cannot be greater than #{self.reference_project_unit.pending_balance({user_id: self.user_id})}"
    end
  end

  def status_changed
    if self.status_changed? && ['success', 'failed'].include?(self.status_was)
      self.errors.add :status, ' cannot be modified for a successful or failed payments'
    end
    if self.status_changed? && ['clearance_pending'].include?(self.status_was) && self.status == 'pending'
      self.errors.add :status, ' cannot be modified to "pending" from "Pending Clearance" status'
    end
  end
end
