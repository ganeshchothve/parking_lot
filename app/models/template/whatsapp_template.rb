#
# Class Whatsapp template to sends the whatsapp message
#
# @author Dnyaneshwar Burgute <dnyaneshwar.burgute@sell.do>
#
class Template::WhatsappTemplate < Template
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :subject_class, type: String
  field :content, type: String

  validates :name, :content, :subject_class, presence: true

  belongs_to :booking_portal_client, class_name: 'Client', inverse_of: :whatsapp_templates
end
