class Account
  include Mongoid::Document
  include Mongoid::Timestamps

  field :account_number, type: Integer # required true

  validates_uniqueness_of :account_number

  has_many :receipts
  belongs_to :phase, optional: true

  def self.available_defaults 
    out = [
      {id: 'true', text: 'True' },
      {id: 'false', text: 'False'}
    ]
  end
end
