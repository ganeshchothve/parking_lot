if defined?(AssetSync) && Rails.env.staging?
  AssetSync.configure do |config|
    config.fog_provider = 'AWS'
    config.fog_region = ENV_CONFIG[:asset_sync]['FOG_REGION']
    config.existing_remote_files = "keep"
    config.fog_directory = ENV_CONFIG[:asset_sync]['FOG_DIRECTORY']
    config.aws_access_key_id = ENV_CONFIG[:asset_sync]['AWS_ACCESS_KEY_ID']
    config.aws_secret_access_key = ENV_CONFIG[:asset_sync]['AWS_SECRET_ACCESS_KEY']

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
end
