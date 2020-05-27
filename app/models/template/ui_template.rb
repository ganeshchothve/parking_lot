# frozen_string_literal: true

class Template::UITemplate < Template
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :subject_class, type: String, default: ''
  field :content, type: String

  validates :name, :content, presence: true

  belongs_to :booking_portal_client, class_name: 'Client', inverse_of: :ui_templates
end
