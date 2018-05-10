AssetSync.configure do |config|
  config.fog_provider = 'Azure Blob'
  config.azure_storage_account_name = ENV_CONFIG[:asset_sync]['AZURE_STORAGE_ACCOUNT_NAME']
  config.azure_storage_access_key = ENV_CONFIG[:asset_sync]['AZURE_STORAGE_ACCESS_KEY']
  config.fog_directory = ENV_CONFIG[:asset_sync]['FOG_DIRECTORY']

  # Invalidate a file on a cdn after uploading files
  # config.cdn_distribution_id = "12345"
  # config.invalidate = ['file1.js']

  # Increase upload performance by configuring your region
  # config.fog_region = 'eu-west-1'
  #
  # Don't delete files from the store
  # config.existing_remote_files = "keep"
  #
  # Automatically replace files with their equivalent gzip compressed version
  # config.gzip_compression = true
  #
  # Use the Rails generated 'manifest.yml' file to produce the list of files to
  # upload instead of searching the assets directory.
  # config.manifest = true
  #
  # Fail silently.  Useful for environments such as Heroku
  # config.fail_silently = true
  #
  # Log silently. Default is `true`. But you can set it to false if more logging message are preferred.
  # Logging messages are sent to `STDOUT` when `log_silently` is falsy
  # config.log_silently = true
end
