class Workflow
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria

  WORKFLOW_BOOKING_STAGES = %w[blocked booked_tentative booked_confirmed cancelled]

  field :stage, type: String

  has_many :pipelines
  belongs_to :booking_portal_client, class_name: 'Client'

  validates :stage, inclusion: { in: WORKFLOW_BOOKING_STAGES }
  validates :stage, uniqueness: true

  accepts_nested_attributes_for :pipelines, allow_destroy: true
end