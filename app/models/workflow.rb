class Workflow
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria

  WORKFLOW_BOOKING_STAGES = %w[blocked booked_tentative booked_confirmed cancelled]

  field :stage, type: String

  has_many :pipelines
  belongs_to :booking_portal_client, class_name: 'Client'

  validates :stage, inclusion: { in: WORKFLOW_BOOKING_STAGES }

  accepts_nested_attributes_for :pipelines, allow_destroy: true

  class << self
    def user_based_scope user, params={}
      custom_scope = {}
      if user.role.in?(User::KYLAS_MARKETPALCE_USERS)
        custom_scope = { booking_portal_client_id: user.booking_portal_client.id }
      end
      custom_scope
    end
  end
end