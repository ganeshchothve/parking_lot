require 'rails_helper'
RSpec.describe Admin::BookingDetailSchemesController, type: :controller do
  describe "updating booking detail scheme" do
    before(:each) do
      client = create(:client)
      @admin = create(:admin)
      sign_in_app(@admin)
      @user = create(:user)
      kyc = create(:user_kyc, creator_id: @user.id, user: @user)
      @developer = create(:developer)
      @project = create(:project, developer_id: @developer.id)
      @project_tower = create(:project_tower, project: @project)
      @project_unit = create(:project_unit, project_tower: @project_tower, project: @project )
      @project_unit.user = @user
      @project_unit.primary_user_kyc_id = kyc.id
      @project_unit.save
      @booking_detail = FactoryBot.create(:booking_detail, user: @user, primary_user_kyc_id: kyc.id)
      @scheme = create(:scheme, project: @project_unit.project, project_tower: @project_unit.project_tower)
      @booking_detail_scheme = FactoryBot.create(:booking_detail_scheme, derived_from_scheme_id: @scheme.id, booking_detail: @booking_detail)
    end

    it "accepts payment adjustment and changes status of scheme when payment adjustment is updated" do
      @project_unit.status = 'under_negotiation'
      @project_unit.save
      booking_detail_scheme_params = FactoryBot.attributes_for(:booking_detail_scheme)
       payment_adjustment_params = FactoryBot.attributes_for(:payment_adjustment)
       put :update, params: {:id => @booking_detail_scheme.id, :booking_detail_scheme => { :payment_adjustments_attributes =>{"1" => payment_adjustment_params }}, :booking_detail_id => @booking_detail.id }
      expect(BookingDetailScheme.first.status).to eq('under_negotiation')
    end
    it "does not accept payment adjustment when the project unit is in booking stages" do
      @project_unit.status = 'blocked'
      @project_unit.save
      booking_detail_scheme_params = FactoryBot.attributes_for(:booking_detail_scheme)
       payment_adjustment_params = FactoryBot.attributes_for(:payment_adjustment)
      expect { put :update, params: {:id => @booking_detail_scheme.id, :booking_detail_scheme => { :payment_adjustments_attributes =>{"1" => payment_adjustment_params }}, :booking_detail_id => @booking_detail.id } }.to change { BookingDetailScheme.last.payment_adjustments.count }.by(0)
    end
  end
end