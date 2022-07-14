class UserNotificationToken
  include Mongoid::Document

  field :token, type: String
  field :os, type: String
  field :device, type: String

  belongs_to :booking_portal_client, class_name: 'Client', optional: true
  embedded_in :user

  # validates :token, :os, presence: true
end