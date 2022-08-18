class Workflow
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria

  WORKFLOW_BOOKING_STAGES = %w[blocked booked_tentative booked_confirmed cancelled]

  field :stage, type: String

  # flags to trigger workflow events in Kylas
  field :create_product, type: Boolean, default: false
  field :deactivate_product, type: Boolean, default: false
  field :update_product_on_deal, type: Boolean, default: false

  has_many :pipelines
  belongs_to :booking_portal_client, class_name: 'Client'

  validates :stage, inclusion: { in: WORKFLOW_BOOKING_STAGES }
  validates :stage, uniqueness: true

  accepts_nested_attributes_for :pipelines, allow_destroy: true
end