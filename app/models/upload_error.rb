class UploadError
  include Mongoid::Document
  include Mongoid::Timestamps

  field :row, type: Array
  field :messages, type: Array, default: []

  belongs_to :booking_portal_client, class_name: 'Client', optional: true
  embedded_in :bulk_upload_report
end
