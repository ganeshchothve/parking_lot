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
  
  validates :name, :subject_class, :title, :url, presence: true
  # validate :url_format

  belongs_to :booking_portal_client, class_name: 'Client', inverse_of: :notification_templates

  def parsed_title object
    begin
      return ERB.new(self.title).result( object.get_binding ).html_safe
    rescue Exception => e
      "Push Notification Title Error"
    end
  end

  def parsed_url object
    begin
      return ERB.new(self.url).result( object.get_binding ).html_safe
    rescue Exception => e
      "/dashboard"
    end
  end
end
