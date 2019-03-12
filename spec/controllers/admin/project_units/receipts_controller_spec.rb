require 'rails_helper'
RSpec.describe Admin::ProjectUnits::ReceiptsController, type: :controller do
  describe 'creating receipt' do
    it 'selects account linked to the phase if phase and account both are present' do
      phase = create(:phase)
      default = create(:razorpay_payment, by_default: true)
      not_default = create(:razorpay_payment, by_default: false)
      not_default.phases << phase
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
      search = Search.create(created_at: Time.now, updated_at: Time.now, bedrooms: 2.0, carpet: nil, agreement_price: nil, all_inclusive_price: nil, project_tower_id: nil, floor: nil, project_unit_id: nil, step: "filter", results_count: nil, user_id: @user.id )
      pubs = ProjectUnitBookingService.new(@project_unit)
      pubs.create_booking_detail(search.id) 
      receipt_params = FactoryBot.attributes_for(:receipt)
      post :create, params: { receipt: receipt_params, user_id: @user.id, project_unit_id: @project_unit.id }
      post :create, params: { receipt: receipt_params, user_id: @user.id, project_unit_id: @project_unit.id }
      receipt = Receipt.first
      receipt.success!
      receipt1 = Receipt.first
      receipt1.success!
      expect(receipt1.account.by_default).to eq(false)
    end
    it 'selects default account when phase is missing or account is missing' do
      phase = create(:phase)
      default = create(:razorpay_payment, by_default: true)
      not_default = create(:razorpay_payment, by_default: false)
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
      search = Search.create(created_at: Time.now, updated_at: Time.now, bedrooms: 2.0, carpet: nil, agreement_price: nil, all_inclusive_price: nil, project_tower_id: nil, floor: nil, project_unit_id: nil, step: "filter", results_count: nil, user_id: @user.id )
      pubs = ProjectUnitBookingService.new(@project_unit)
      pubs.create_booking_detail(search.id)
      receipt_params = FactoryBot.attributes_for(:receipt)
      post :create, params: { receipt: receipt_params, user_id: @user.id, project_unit_id: @project_unit.id }
      receipt = Receipt.first
      receipt.success!
      expect(receipt.account.by_default).to eq(true)
    end
  end
end
