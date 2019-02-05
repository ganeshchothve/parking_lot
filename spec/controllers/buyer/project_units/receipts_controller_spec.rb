require 'rails_helper'
RSpec.describe Buyer::ProjectUnits::ReceiptsController, type: :controller do
describe "creating receipt" do
    it "selects default account when this is first booking for the tower" do
      default = Account::RazorpayPayment.new(account_number: '123412341234', by_default: 'true', key: 'rzp_test_NTQGRS3ia0hiWY', secret: "pzM04pY4CJFkHbM3iWKBjDhN" )
      default.save
      not_default = Account::RazorpayPayment.new(account_number: '123412341235', by_default: 'false', key: 'rzp_test_NTQGRS3ia0hiWY', secret: "pzM04pY4CJFkHbM3iWKBjDhN" )
      not_default.save
      client = create(:client)
      admin = create(:admin)
      @user = create(:user)
      sign_in_app(@user)
      kyc = create(:user_kyc, creator_id: @user.id, user: @user)
      @project_unit = create(:project_unit)
      project_tower = @project_unit.project_tower
      project_tower.account = not_default
      project_tower.save
      @project_unit.status = 'hold'
      @project_unit.user = @user 
      @project_unit.primary_user_kyc_id = kyc.id
      @project_unit.save
      receipt_params = FactoryBot.attributes_for(:receipt)
      post :create, params: {receipt: receipt_params, project_unit_id: @project_unit.id }
      expect(Receipt.first.account.by_default).to eq(true)
    end
    it "selects account linked to the tower when this not first booking for the tower" do
      default = Account::RazorpayPayment.new(account_number: '123412341234', by_default: 'true', key: 'rzp_test_NTQGRS3ia0hiWY', secret: "pzM04pY4CJFkHbM3iWKBjDhN" )
      default.save
      not_default = Account::RazorpayPayment.new(account_number: '123412341235', by_default: 'false', key: 'rzp_test_NTQGRS3ia0hiWY', secret: "pzM04pY4CJFkHbM3iWKBjDhN" )
      not_default.save
      client = create(:client)
      admin = create(:admin)
      @user = create(:user)
      sign_in_app(@user)
      kyc = create(:user_kyc, creator_id: @user.id, user: @user)
      @project_unit = create(:project_unit)
      project_tower = @project_unit.project_tower
      project_tower.account = not_default
      project_tower.save
      @project_unit.status = 'hold'
      @project_unit.user = @user 
      @project_unit.primary_user_kyc_id = kyc.id
      @project_unit.save
      receipt_params = FactoryBot.attributes_for(:receipt)
      post :create, params: {receipt: receipt_params, user_id: @user.id, project_unit_id: @project_unit.id }
      @project_unit.status = 'blocked'
      @project_unit.save
      a_project_unit = create(:project_unit)
      a_project_unit.status = 'hold'
      a_project_unit.user = @user 
      a_project_unit.primary_user_kyc_id = kyc.id
      a_project_unit.save
      post :create, params: {receipt: receipt_params, project_unit_id: a_project_unit.id }
      expect(Receipt.last.account.by_default).to eq(false)
    end
  end
end