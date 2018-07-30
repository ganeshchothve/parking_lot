CarrierWave.configure do |config|
  if Rails.env.production? || Rails.env.staging?
    config.storage = Fog
    config.fog_directory  = ENV_CONFIG[:asset_sync]['FOG_DIRECTORY']
    config.fog_public     = false
    config.fog_attributes = {'Cache-Control' => 'max-age=315576000'}

    config.fog_credentials = {
      provider:                'AWS',
      aws_access_key_id:       ENV_CONFIG[:asset_sync]['AWS_SECRET_ACCESS_KEY'],
      aws_secret_access_key:   ENV_CONFIG[:asset_sync]['AWS_ACCESS_KEY_ID'],
      aws_signature_version:   2,
      region:                  ENV_CONFIG[:asset_sync]['FOG_REGION']
    }
  end
end
