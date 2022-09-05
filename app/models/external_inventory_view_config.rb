class ExternalInventoryViewConfig
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods

  field :provider, type: String, default: "foyr"
  field :url, type: String
  field :status, type: String, default: "inactive"

  belongs_to :booking_portal_client, class_name: "Client"

  validates :provider, inclusion: {in: I18n.t("mongoid.models.external_inventory_view_config.available_providers").keys.map(&:to_s) }, if: Proc.new{|e| e.enabled?}
  validates :status, inclusion: {in: I18n.t("mongoid.models.external_inventory_view_config.available_statuses").keys.map(&:to_s) }, if: Proc.new{|e| e.enabled?}
  validates :url, presence: true, if: Proc.new{|e| e.enabled? }

  def self.available_providers
    [
      {id: "Foyr", text: "Foyr 3D Inventory View"}
    ]
  end

  def self.available_statuses
    [
      {id: "active", text: "Active"},
      {id: "inactive", text: "Inactive"}
    ]
  end

  def enabled?
    status == "active"
  end
end
