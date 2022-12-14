class AssetObserver < Mongoid::Observer
    def before_validation asset
      asset.booking_portal_client_id = asset.assetable.booking_portal_client_id if asset.booking_portal_client_id.blank?
    end
end