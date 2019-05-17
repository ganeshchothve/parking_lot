require 'rails_helper'
RSpec.describe Admin::UsersController, type: :controller do
  describe "GET index" do
    it "success response" do
      user = create(:admin)
      sign_in_app(user)
      get :index
      expect(response.status).to eq(200)
    end
  end
  describe "UPDATE action" do
    before(:each) do
      admin = create(:admin)
      sign_in_app(admin) 
    end
    %w[user].each do |user_role|
      context "for #{user_role}" do
        it ",update is successful" do 
          user = create(user_role)
          user_attributes = attributes_for(:user)
          patch :update, params: {id: user.id, user: user_attributes}
          expect(response.request.flash[:notice]).to eq('User Profile updated successfully.')
        end 
        it "sends premium field, does not update premium field" do 
          user = create(user_role)
          user_attributes = attributes_for(:user)
          user_attributes[:premium] = true
          patch :update, params: {id: user.id, user: user_attributes}
          expect(user.reload.premium).to eq(false)
        end
      end 
    end
    context "for channel_partner" do
      it "sends premium field, updates premium field" do 
        user = create(:user)
        user.set(role: 'channel_partner')
        user_attributes = attributes_for(:user)
        user_attributes[:premium] = true
        patch :update, params: {id: user.id, user: user_attributes}
        expect(user.reload.premium).to eq(true)
      end  
    end
  end
end