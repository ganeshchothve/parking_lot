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

  describe "confirm user account" do
    %w[admin superadmin].each do |user_role|
      context "by #{user_role}" do
        it "then user gets confirmed." do
          @client = create(:client)
          admin = create(user_role, booking_portal_client_id: @client)
          project = create(:project, booking_portal_client: @client)
          user = create(:unconfirmed_user, booking_portal_client_id: @client)
          sign_in_app(admin)
          patch :confirm_user, params: {id: user.id}
          expect(user.reload.confirmed_at).to_not eq(nil)
          expect(user.reload.confirmed_by.id).to eq(admin.id)
          expect(user.reload.encrypted_password).to_not eq(nil)
        end
      end
    end
    # ["employee_user", "channel_partner", "cp", "crm", "cp_admin", "sales", "gre", "customer", "sales_admin"] will work similarly for all these roles
    context "by user" do
      it "then user cannot be confirmed." do
        non_admin = create(:user)
        user = create(:unconfirmed_user)
        sign_in_app(non_admin)
        patch :confirm_user, params: {id: user.id}
        expect(response.request.flash[:alert]).to eq("Only administrator users are allowed.")
      end
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