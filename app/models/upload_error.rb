class UploadError
  include Mongoid::Document
  include Mongoid::Timestamps

  field :row, type: Array
  field :errors, type: Array

  belongs_to :bulk_upload_report
end
