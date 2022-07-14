class TokenType
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :token_prefix, type: String
  field :token_seed, type: Integer, default: 0
  field :token_seed_backup, type: Integer
  field :token_amount, type: Integer

  belongs_to :booking_portal_client, class_name: 'Client', optional: true
  belongs_to :project
  has_many :receipts

  validates :name, presence: true, uniqueness: {scope: :project_id}
  validates :token_prefix, :token_amount, presence: true

  def init
    Mongoid::Autoinc::Incrementor.new('Receipt', :token_number, {seed: (token_seed_backup || token_seed), scope: "p#{project_id}_t#{id}"}).send(:exists?)
  end

  def de_init
    self.update(token_seed_backup: incrementor['c'])
    _incrementor.send(:find).try(:find_one_and_delete) if incrementor_exists?
    !incrementor_exists?
  end

  def incrementor_exists?
    _incrementor.send(:exists?)
  end

  def incrementor
    _incrementor.send(:find).first
  end

  def _incrementor
    Mongoid::Autoinc::Incrementor.new('Receipt', :token_number, {scope: "p#{project_id}_t#{id}"})
  end

  private

  def reset_incrementor
    _incrementor.send(:find).find_one_and_update({c: token_seed}, upsert: true, return_document: :after).fetch('c')
  end
end
