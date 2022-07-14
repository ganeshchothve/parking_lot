class InterestedProject
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include InterestedProjectStateMachine
  include ApplicationHelper
  extend ApplicationHelper

  STATUS = %w(subscribed approved rejected blocked).freeze

  field :status, type: String, default: 'subscribed'
  field :rejection_reason, type: String

  belongs_to :booking_portal_client, class_name: 'Client'
  belongs_to :user
  belongs_to :project

  validates :project_id, uniqueness: { scope: :user_id, message: ->(object, data) { "#{object.project.name} is already subscribed" } }
end
