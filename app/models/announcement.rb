class Announcement
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods
  include ApplicationHelper
  extend ApplicationHelper
  extend FilterByCriteria
  extend DocumentsConcern

  DOCUMENT_TYPES = ['photo', 'collateral']
  CATEGORIES = %w(general new_launch events brokerage_alert)

  field :category, type: String
  field :title, type: String
  field :content, type: String
  field :date, type: String
  field :is_active, type: Boolean, default: false
  has_many :assets, as: :assetable

  belongs_to :booking_portal_client, class_name: 'Client'

  validates :category, inclusion: { in: CATEGORIES }

  scope :filter_by_published, ->{ where(is_active: true) }

  def self.user_based_scope(user, params = {})
    custom_scope = {}
    if user.role.in?(%w(superadmin))
      custom_scope = { }
    end
    custom_scope.merge!({booking_portal_client_id: user.booking_portal_client.id})
    custom_scope
  end

  def photo_assets_json
    self.assets.where(booking_portal_client_id: self.booking_portal_client_id, document_type: "photo").as_json(Asset.ui_json)
  end

  def collateral_assets_json
    self.assets.where(booking_portal_client_id: self.booking_portal_client_id, document_type: "collateral").as_json(Asset.ui_json)
  end

end
