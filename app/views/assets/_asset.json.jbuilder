if asset.file.file.exists?
  json.url asset.file.url
  json.file_size asset.file_size
  json.id asset.id
  json.content_type asset.file.content_type
end
