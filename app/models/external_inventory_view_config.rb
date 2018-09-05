class ExternalInventoryViewConfig
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include InsertionStringMethods

  field :provider, type: String, default: "foyr"
  field :url, type: String
  field :status, type: String, default: "inactive"

  belongs_to :booking_portal_client, class_name: "Client"

  validates :provider, inclusion: {in: Proc.new{ ExternalInventoryViewConfig.available_providers.collect{|x| x[:id]} } }, if: Proc.new{|e| e.enabled?}
  validates :status, inclusion: {in: Proc.new{ ExternalInventoryViewConfig.available_statuses.collect{|x| x[:id]} } }, if: Proc.new{|e| e.enabled?}
  validates :url, presence: true

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
