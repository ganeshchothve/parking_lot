class BulkUploadReport
  include Mongoid::Document
  include Mongoid::Timestamps

  field :total_rows, type: Integer
  field :success_count, type: Integer
  field :failure_count, type: Integer

  belongs_to :uploaded_by, class: User
  has_many :upload_errors
end
