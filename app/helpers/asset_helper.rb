module AssetHelper
  def custom_assets_path
    dashboard_path('remote-state': assetables_path(assetable_type: current_user.class.model_name.i18n_key.to_s, assetable_id: current_user.id) )
  end

  def assetable_document_types(assetable, current_client)
    assetable.class.doc_types(current_client).collect{ |doc| [t("mongoid.attributes.#{assetable.model_name.element}/file_types.#{doc}"), doc] }
  end
end
