class Video
  include Mongoid::Document
  include Mongoid::Timestamps
  extend FilterByCriteria

  field :description, type: String
  field :embedded_video, type: String

  mount_uploader :thumbnail, DocUploader

  belongs_to :videoable, polymorphic: true

  validates :description, :embedded_video, presence: true
end
