if Rails.env.production? || Rails.env.staging?
  CarrierWave.configure do |config|
    config.azure_storage_account_name = ENV_CONFIG[:carrierwave][:AZURE_STORAGE_ACCOUNT_NAME]
    config.azure_storage_access_key = ENV_CONFIG[:carrierwave][:AZURE_STORAGE_ACCESS_KEY]
    config.azure_storage_blob_host = ENV_CONFIG[:carrierwave][:AZURE_STORAGE_BLOB_HOST]
    config.azure_container = ENV_CONFIG[:carrierwave][:AZURE_CONTAINER]
    config.root = Rails.root
    config.directory_permissions = 0777

    #config.fog_provider = 'fog/aws'
    #config.fog_credentials = {
    #  provider:              'AWS',
    #  aws_access_key_id:     ENV_CONFIG[:carrierwave]['AWS_ACCESS_KEY_ID'],
    #  aws_secret_access_key: ENV_CONFIG[:carrierwave]['AWS_SECRET_ACCESS_KEY'],
    #  use_iam_profile:       true,
    #  region:                ENV_CONFIG[:carrierwave]['FOG_REGION']
    #}
    #config.fog_directory  = ENV_CONFIG[:carrierwave]['FOG_DIRECTORY']
    #config.fog_public     = false
    #config.fog_attributes = { cache_control: "public, max-age=#{365.days.to_i}" }
  end
else
  CarrierWave.configure do |config|
    config.asset_host = ActionController::Base.asset_host
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
