require 'rails_helper'
RSpec.describe Buyer::ProjectUnits::ReceiptsController, type: :controller do
  describe 'creating receipt' do
    it 'selects not default account when there is a account linked to the phase' do
      phase = create(:phase)
      default = create(:razorpay_payment, by_default: true)
      not_default = create(:razorpay_payment, by_default: false)
      not_default.phases << phase
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
      expect(Receipt.first.account.by_default).to eq(false)
    end
    it 'selects default account when there is no account linked to the phase' do
      phase = create(:phase)
      default = create(:razorpay_payment, by_default: true)
      not_default = create(:razorpay_payment, by_default: false)
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
      expect(Receipt.last.account.by_default).to eq(true)
    end
  end
end
