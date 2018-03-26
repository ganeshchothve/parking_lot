module FileUploaderHelper
  def allowed_file_extensions uploder_type
    instance = uploder_type.constantize.new
    (instance.respond_to?(:extension_white_list) && instance.extension_white_list.present? )? instance.extension_white_list.join(",") : nil
  end
end
