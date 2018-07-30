CarrierWave.configure do |config|
  if Rails.env.production? || Rails.env.staging?
    config.fog_credentials = {
      provider: 'AWS',
      region: ENV_CONFIG[:asset_sync]['FOG_REGION'],
      aws_access_key_id: ENV_CONFIG[:asset_sync]['AWS_ACCESS_KEY_ID'],
      aws_secret_access_key: ENV_CONFIG[:asset_sync]['AWS_SECRET_ACCESS_KEY']
    }
    config.fog_directory = ENV_CONFIG[:asset_sync]['FOG_DIRECTORY']
  end
end
