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
  validates :start_value, numericality: { greater_than: 0 }
  validates :end_value, numericality: { greater_than: 0, allow_blank: true }
  validates :payment_adjustment, copy_errors_from_child: true
  validate :start_value_lte_end_value

  default_scope -> {asc(:stage)}

  accepts_nested_attributes_for :payment_adjustment, allow_destroy: true

  def start_value_lte_end_value
    errors.add :start_value, 'must be <= end value' if end_value? && start_value > end_value
  end

  def name_in_error
    "Stage #{stage}"
  end
end
