class FundAccount
  include Mongoid::Document
  include Mongoid::Timestamps
  include ApplicationHelper
  include CrmIntegration

  field :account_type, type: String, default: 'vpa'
  field :address, type: String
  field :is_active, type: Boolean, default: false
  field :old_address, type: String

  belongs_to :booking_portal_client, class_name: 'Client', optional: true
  belongs_to :user

  validates :address, :account_type, presence: true
end
