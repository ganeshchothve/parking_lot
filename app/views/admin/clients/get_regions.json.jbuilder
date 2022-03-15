json.array! @regions do |region|
  json.extract! region, :city, :partner_regions
end
