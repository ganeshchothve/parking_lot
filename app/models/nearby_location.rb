class NearbyLocation
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include ApplicationHelper
  extend ApplicationHelper

  field :distance, type: String # in kms
  field :destination, type: String

  belongs_to :project

  validates :distance, :destination, presence: true
end
