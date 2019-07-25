class Account
  include Mongoid::Document
  include Mongoid::Timestamps

  field :account_number, type: Integer # required true
  field :name, type: String
  field :by_default, type: Boolean, default: false

  validates_uniqueness_of :account_number, :name

  has_many :receipts, foreign_key: 'account_number'
  has_many :phases

  before_destroy :check_for_receipts, prepend: true

  validate :unique_default_account

  def ds_name
    "#{name} (#{account_number})"
  end

  def account_type
    _type.underscore.split('/')[1]
  end

  private

  def check_for_receipts
    if receipts.any?
      self.errors.add :base, 'Cannot delete account which has receipts associated with it.'
      false
      throw(:abort)
    end
  end

  def unique_default_account
    if self.by_default && !::Account.where(by_default: true, _type: self._type).nin(_id: self.id).count.zero?
      self.errors.add(:by_default, 'Only one can set as default.')
    end
  end
end
