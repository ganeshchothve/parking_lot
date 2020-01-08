require 'rails_helper'
RSpec.describe Admin::InventoryUploadsController, type: :controller do
  before(:each) do
    @admin = create(:admin)
    sign_in_app(@admin)
  end

  describe "create" do
    context "when file has all valid rows" do
      it "should upload all the rows successfully" do
        assets_attributes = FactoryBot.attributes_for(:correct_csv)
        post :create, params: {bulk_upload_report: {uploaded_by_id: @admin.id, asset_attributes: assets_attributes}}
        expect(ProjectUnit.count).to eq(3)
        expect(BulkUploadReport.first.reload.total_rows).to eq(3)
        expect(BulkUploadReport.first.reload.success_count).to eq(3)
      end
    end
    context "when file is empty" do
      it "should not upload any units" do
        assets_attributes = FactoryBot.attributes_for(:empty_file)
        post :create, params: {bulk_upload_report: {uploaded_by_id: @admin.id, asset_attributes: assets_attributes}}
        expect(ProjectUnit.count).to eq(0)
        expect(BulkUploadReport.first.reload.total_rows).to eq(0)
        expect(BulkUploadReport.first.reload.success_count).to eq(0)
      end
    end
    context "when there is error in header row of csv" do
      it "should not upload any units" do
        assets_attributes = FactoryBot.attributes_for(:incorrect_header)
        post :create, params: {bulk_upload_report: {uploaded_by_id: @admin.id, asset_attributes: assets_attributes}}
        expect(ProjectUnit.count).to eq(0)
        expect(BulkUploadReport.first.reload.total_rows).to eq(3)
        expect(BulkUploadReport.first.reload.success_count).to eq(0)
      end
    end
    context "when unit data is not valid" do
      context "only one row is present" do
        it "should not upload any units" do
          assets_attributes = FactoryBot.attributes_for(:invalid_file_1)
          post :create, params: {bulk_upload_report: {uploaded_by_id: @admin.id, asset_attributes: assets_attributes}}
          expect(ProjectUnit.count).to eq(0)
          expect(BulkUploadReport.first.reload.total_rows).to eq(1)
          expect(BulkUploadReport.first.reload.success_count).to eq(0)
        end
      end 
      context "when 2 rows are present and second is valid" do
        it "should upload only one unit" do
          assets_attributes = FactoryBot.attributes_for(:invalid_file_2)
          post :create, params: {bulk_upload_report: {uploaded_by_id: @admin.id, asset_attributes: assets_attributes}}
          expect(ProjectUnit.count).to eq(1)
          expect(BulkUploadReport.first.reload.total_rows).to eq(2)
          expect(BulkUploadReport.first.reload.success_count).to eq(1)
        end
      end
      context "when unit with same erp id is present in the system" do
        context "when only one row is present" do
          it "should not upload any units" do
            assets_attributes = FactoryBot.attributes_for(:repeat_file)
            post :create, params: {bulk_upload_report: {uploaded_by_id: @admin.id, asset_attributes: assets_attributes}}
            assets_attributes = FactoryBot.attributes_for(:repeat_file)
            post :create, params: {bulk_upload_report: {uploaded_by_id: @admin.id, asset_attributes: assets_attributes}}
            expect(ProjectUnit.count).to eq(1)
            expect(BulkUploadReport.count).to eq(2)
          end
        end
      end
    end
  end
end
