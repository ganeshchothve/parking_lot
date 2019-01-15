class GalleryPolicy < ClientPolicy

  def asset_create?
    true
  end

  def permitted_attributes params={}
    []
  end
end
