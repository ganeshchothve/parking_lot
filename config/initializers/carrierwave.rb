CarrierWave.configure do |config|
  config.azure_storage_account_name = ENV_CONFIG[:asset_sync]['AZURE_STORAGE_ACCOUNT_NAME']
  config.azure_storage_access_key = ENV_CONFIG[:asset_sync]['AZURE_STORAGE_ACCESS_KEY']
  config.azure_container = ENV_CONFIG[:asset_sync]['FOG_DIRECTORY']
end
