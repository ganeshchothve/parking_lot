#
# Class Notification template to sends the Mobile Notification
#

class Template::NotificationTemplate < Template
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :subject_class, type: String
  field :title, type: String
  field :url, type: String
  field :event_based, type: Boolean, default: false
  
  validates :name, :content, :subject_class, :title, :event_based, presence: true
  validates :url, presence: true, if: proc { |template| !template.event_based? }

  belongs_to :booking_portal_client, class_name: 'Client', inverse_of: :notification_templates
end
