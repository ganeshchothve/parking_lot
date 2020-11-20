class Invoice
  include Mongoid::Document
  include Mongoid::Timestamps
  include InsertionStringMethods
  extend FilterByCriteria

  field :amount, type: Float, default: 0.0
  field :status, type: String, default: 'pending'
  field :registration_status, type: String
  field :raised_date, type: Date
  field :processing_date, type: Date
  field :approved_date, type: Date
  field :cheque_handover_date, type: Date
  field :comments, type: String
  field :ladder_id, type: BSON::ObjectId
  field :ladder_stage, type: Integer

  belongs_to :project
  belongs_to :booking_detail
  belongs_to :incentive_scheme
  has_one :cheque, class_name: 'Receipt'

  validates :ladder_id, presence: true
  validates :booking_detail_id, uniqueness: { scope: [:incentive_scheme_id, :ladder_id] }
  validates :amount, numericality: { greater_than: 0 }
end
