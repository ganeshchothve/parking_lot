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
if Rails.env.test?

  CarrierWave.configure do |config|
    config.storage = :file
    config.enable_processing = false
  end

  # make sure uploader is auto-loaded FileUploader

  CarrierWave::Uploader::Base.descendants.each do |klass|
    next if klass.anonymous?
    klass.class_eval do
      def cache_dir
        "#{Rails.root}/spec/support/uploads/tmp"
      end

      def store_dir
        "#{Rails.root}/spec/support/uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
      end
    end
  end
end

CarrierWave.configure do |config|
  config.asset_host = ActionController::Base.asset_host
end
