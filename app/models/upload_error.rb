class UploadError
  include Mongoid::Document
  include Mongoid::Timestamps

  field :row, type: Array
  field :messages, type: Array, default: []

  embedded_in :bulk_upload_report
end
