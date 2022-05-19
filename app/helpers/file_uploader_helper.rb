module FileUploaderHelper
  def allowed_file_extensions uploder_type, assetable
    if uploder_type=="AssetUploader"
      exts = case assetable
      when BulkUploadReport
        %w(csv)
      when User, Receipt, IncentiveDeduction
        %w(PNG png JPEG jpeg JPG jpg PDF pdf)
      when Client
        %w(PNG png JPEG jpeg JPG jpg PDF pdf CSV csv SVG svg)
      else
        %w(PNG png JPEG jpeg JPG jpg PDF pdf zip ZIP)
      end
      exts.join(',')
    elsif uploder_type=="PublicAssetUploader"
      PublicAsset::ALLOWED_EXTENSIONS.join(',')
    end
  end
end
