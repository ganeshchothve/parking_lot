class Ladder
  include Mongoid::Document
  include Mongoid::Timestamps
  include InsertionStringMethods
  extend FilterByCriteria

  field :stage, type: Integer
  field :start_value, type: Integer
  field :end_value, type: Integer
  # Build inclusive ladders by default. Not supporting exclusive ladders for now (keep it as future scope)
  # TODO: Handle exclusive ladders behavior.
  field :inclusive, type: Boolean, default: true

  embedded_in :incentive_scheme
  embeds_one :payment_adjustment, as: :payable, autobuild: true
  has_many :invoices

  validates :start_value, :payment_adjustment, presence: true
  validates :stage, uniqueness: true, numericality: { greater_than: 0 }

  accepts_nested_attributes_for :payment_adjustment, allow_destroy: true
end
