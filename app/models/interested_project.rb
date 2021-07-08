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

  belongs_to :user
  belongs_to :project
end
