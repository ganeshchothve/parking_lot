class Template
  include Mongoid::Document
  include Mongoid::Timestamps

  field :content, type: String

  belongs_to :booking_portal_client, class_name: "Client"

  validates :content, presence: true

  def parsed_content object
    return ERB.new(self.content).result( object.get_binding ).html_safe
  end
end
