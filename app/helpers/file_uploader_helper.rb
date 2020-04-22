module FileUploaderHelper
  def allowed_file_extensions uploder_type, assetable
    exts = case assetable
    when BulkUploadReport
      %w(csv)
    when User, Receipt
      %w(PNG png JPEG jpeg JPG jpg PDF pdf)
    when Client
      %w(PNG png JPEG jpeg JPG jpg PDF pdf csv)
    else
      %w(PNG png JPEG jpeg JPG jpg PDF pdf)
    end
    exts.join(',')
  end
end
