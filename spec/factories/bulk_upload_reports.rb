FactoryBot.define do
  factory :bulk_upload_report do
    before(:create) do |bulk_upload_report|
      bulk_upload_report.uploaded_by_id = User.where(role: {"$in": ['admin', 'superadmin']}).first
      bulk_upload_report.asset = create(:asset, assetable: bulk_upload_report)
    end
  end
end
