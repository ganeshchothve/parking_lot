if Rails.env.production? || Rails.env.staging?
  CarrierWave.configure do |config|
    config.fog_provider = 'fog/aws'
    config.fog_credentials = {
      provider:              'AWS',
      aws_access_key_id:     ENV_CONFIG[:asset_sync]['AWS_ACCESS_KEY_ID'],
      aws_secret_access_key: ENV_CONFIG[:asset_sync]['AWS_SECRET_ACCESS_KEY'],
      use_iam_profile:       true,
      region:                ENV_CONFIG[:asset_sync]['FOG_REGION']
    }
    config.fog_directory  = ENV_CONFIG[:asset_sync]['FOG_DIRECTORY']
    config.fog_public     = true
    config.fog_attributes = { cache_control: "public, max-age=#{365.days.to_i}" }
  end
end
