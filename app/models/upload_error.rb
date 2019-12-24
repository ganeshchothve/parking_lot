class UploadError
  include Mongoid::Document
  include Mongoid::Timestamps

  field :row, type: Array
  field :upload_errors, type: Array

  embedded_in :bulk_upload_report
end
