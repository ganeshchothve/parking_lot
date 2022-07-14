class Specification
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include ApplicationHelper
  extend ApplicationHelper

  CATEGORIES = %w( structure painting flooring toilets kitchen )

  field :category, type: String
  field :description, type: String
  
  belongs_to :booking_portal_client, class_name: 'Client', optional: true
  belongs_to :project

  validates :category, :description, presence: true
  validates :category, uniqueness: { scope: :project_id }
  validates :category, inclusion: { in: ::Specification::CATEGORIES }, allow_blank: true
end