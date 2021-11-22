class Announcement
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include ApplicationHelper
  extend ApplicationHelper
  extend FilterByCriteria

  DOCUMENT_TYPES = []
  CATEGORIES = %w(general new_launch events brokerage_alert)

  field :category, type: String
  field :title, type: String
  field :content, type: String
  field :date, type: Date

  has_many :assets, as: :assetable

  validates :category, inclusion: { in: CATEGORIES }

  def self.user_based_scope(user, params = {})
    custom_scope = {}
  end

end
