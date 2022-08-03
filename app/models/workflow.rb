class Workflow
  include Mongoid::Document
  include Mongoid::Timestamps

  WORKFLOW_BOOKING_STAGES = %w[blocked booked_tentative booked_confirmed cancelled]

  field :stage, type: String

  has_many :pipelines
  # belongs_to :booking_portal_client, class_name: 'Client'

  validates :stage, inclusion: { in: WORKFLOW_BOOKING_STAGES }

  accepts_nested_attributes_for :pipelines
end