class NearbyLocation
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include ApplicationHelper
  extend ApplicationHelper

  UNITS = %w(km min)

  field :distance, type: String
  field :unit, type: String
  field :destination, type: String

  belongs_to :booking_portal_client, class_name: 'Client', optional: true
  belongs_to :project

  validates :distance, :unit, :destination, presence: true
  validates :unit, inclusion: { in: UNITS }
end
