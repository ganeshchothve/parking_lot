class InterestedCampaign
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include InterestedCampaignStateMachine
  include ApplicationHelper
  extend ApplicationHelper

  STATUS = %w(subscribed participating).freeze

  field :status, type: String, default: 'subscribed'
  field :amount, type: Integer

  belongs_to :booking_portal_client, class_name: 'Client', optional: true
  belongs_to :user
  belongs_to :campaign
end
