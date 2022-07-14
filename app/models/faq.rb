class Faq
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include ApplicationHelper
  extend ApplicationHelper

  field :question, type: String
  field :answer, type: String
  
  belongs_to :questionable, polymorphic: true
  belongs_to :booking_portal_client, class_name: 'Client', optional: true
end
