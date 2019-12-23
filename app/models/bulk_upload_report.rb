class BulkUploadReport
  include Mongoid::Document
  include Mongoid::Timestamps

  field :total_rows, type: Integer
  field :success_count, type: Integer
  field :failure_count, type: Integer

  belongs_to :uploaded_by, class_name: 'User'
  embeds_many :upload_errors
  has_many :assets, as: :assetable

  accepts_nested_attributes_for :assets
end
