module PublicAssetsHelper
  def assetable_public_document_types(assetable)
    assetable.class::PUBLIC_DOCUMENT_TYPES.collect{ |doc| [t("mongoid.attributes.#{assetable.model_name.element}/file_types.#{doc}"), doc] }
  end
end
