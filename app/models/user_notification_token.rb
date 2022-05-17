class UserNotificationToken
  include Mongoid::Document

  field :token, type: String
  field :os, type: String
  field :device, type: String

  embedded_in :user

  # validates :token, :os, presence: true
end