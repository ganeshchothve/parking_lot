require 'rails_helper'
RSpec.describe BookingDetailSchemesController, type: :controller do
  describe "updating booking detail scheme" do
    before(:each) do
      client = create(:client)
      admin = create(:admin)
      sign_in_app(admin)
      @user = create(:user)
      kyc = create(:user_kyc, creator_id: @user.id, user: @user)
      @project_unit = create(:project_unit)
      @project_unit.status = 'hold'
      @project_unit.user = @user
      @project_unit.primary_user_kyc_id = kyc.id
      @project_unit.save
      @receipt = create(:receipt, user: @user, creator_id: admin.id, project_unit: @project_unit)
    end

    it "success response" do
      debugger
    end
  end
end