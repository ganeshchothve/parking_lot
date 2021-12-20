module PublicAssetsHelper
  def custom_assets_path
    dashboard_path('remote-state': public_assetables_path(public_assetable_type: current_user.class.model_name.i18n_key.to_s, public_assetable_id: current_user.id) )
  end

  def assetable_public_document_types(assetable)
    assetable.class::PUBLIC_DOCUMENT_TYPES.collect{ |doc| [t("mongoid.attributes.#{assetable.model_name.element}/file_types.#{doc}"), doc] }
  end
end
