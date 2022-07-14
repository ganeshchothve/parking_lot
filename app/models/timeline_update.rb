class TimelineUpdate
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include ApplicationHelper
  extend ApplicationHelper

  DOCUMENT_TYPES = %w[images].freeze

  field :name, type: String
  field :description, type: String
  field :date, type: Date
  
  belongs_to :booking_portal_client, class_name: 'Client', optional: true
  belongs_to :project
  has_many :assets, as: :assetable

  validates :name, :description, :date, presence: true
end