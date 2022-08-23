class Coupon
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :description, type: String
  field :start_token_number, type: Integer
  field :end_token_number, type: Integer
  field :value, type: Float
  field :variable_discount, type: Float

  belongs_to :receipt
  belongs_to :discount, optional: true
  # embeds_many :payment_adjustments, as: :payable

  # accepts_nested_attributes_for :payment_adjustments, allow_destroy: true

  validates :name, :start_token_number, :end_token_number, presence: true
end

