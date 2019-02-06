require 'rails_helper'
RSpec.describe Buyer::ProjectUnits::ReceiptsController, type: :controller do
  describe 'creating receipt' do
    it 'selects default account when this is first booking for the tower' do
      phase = create(:phase)
      default = create(:razorpay_payment, by_default: true)
      not_default = create(:razorpay_payment, by_default: false, phase: phase)
      client = create(:client)
      admin = create(:admin)
      @user = create(:user)
      sign_in_app(@user)
      kyc = create(:user_kyc, creator_id: @user.id, user: @user)
      @project_unit = create(:project_unit)
      @project_unit.status = 'hold'
      @project_unit.user = @user
      @project_unit.primary_user_kyc_id = kyc.id
      @project_unit.save
      receipt_params = FactoryBot.attributes_for(:receipt)
      post :create, params: { receipt: receipt_params, user_id: @user.id, project_unit_id: @project_unit.id }
      expect(Receipt.first.account.by_default).to eq(true)
    end
    it 'selects account linked to the tower when this not first booking for the tower' do
      phase = create(:phase)
      default = create(:razorpay_payment, by_default: true)
      not_default = create(:razorpay_payment, by_default: false, phase: phase)
      client = create(:client)
      admin = create(:admin)
      @user = create(:user)
      sign_in_app(@user)
      kyc = create(:user_kyc, creator_id: @user.id, user: @user)
      @project_unit = create(:project_unit)
      @project_unit.status = 'hold'
      @project_unit.user = @user
      @project_unit.primary_user_kyc_id = kyc.id
      @project_unit.save
      receipt_params = FactoryBot.attributes_for(:receipt)
      post :create, params: { receipt: receipt_params, user_id: @user.id, project_unit_id: @project_unit.id }
      post :create, params: { receipt: receipt_params, user_id: @user.id, project_unit_id: @project_unit.id }
      expect(Receipt.last.account.by_default).to eq(false)
    end
  end
end
