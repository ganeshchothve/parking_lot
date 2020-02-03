require 'rails_helper'
RSpec.describe Admin::BulkUploadReportsController, type: :controller do
  %w[superadmin admin].each do |user_role|
    before(:each) do
      admin = create(user_role)
      sign_in_app(admin)
    end

    describe "index" do
      it "should display all the bulk upload reports" do
        bulk_upload_report_count = BulkUploadReport.count
        get :index
        expect(assigns(:bulk_upload_reports).count).to eq(bulk_upload_report_count)
      end
    end

    describe "show" do
      it "should display details of one bulk upload report" do
        bulk_upload_report = create(:bulk_upload_report)
        get :show, params: { id: bulk_upload_report.id }
        expect(response.status).to eq(200)
      end
    end

    describe "show errors" do
      it "should display all the errors embedded in bulk upload report" do
        bulk_upload_report = create(:bulk_upload_report)
        bulk_upload_report.upload_errors << build(:upload_error)
        get :show_errors, params: { id: bulk_upload_report.id, upload_error_id: bulk_upload_report.upload_errors.first}
        expect(response.status).to eq(200)
      end
    end
  end
end