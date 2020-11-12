class Ladder
  include Mongoid::Document
  include Mongoid::Timestamps
  include InsertionStringMethods
  extend FilterByCriteria

  field :stage, type: Integer
  field :start_value, type: Integer
  field :end_value, type: Integer
  field :inclusive, type: Boolean, default: true

  embeds_one :payment_adjustment, as: :payable, autobuild: true
  embedded_in :incentive_scheme

  validates :start_value, :payment_adjustment, presence: true
  validates :stage, uniqueness: true, numericality: { greater_than: 0 }

  accepts_nested_attributes_for :payment_adjustment, allow_destroy: true
end
