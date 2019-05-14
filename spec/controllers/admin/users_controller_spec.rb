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
          admin = create(user_role)
          user = create(:unconfirmed_user)
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
        expect(response.request.flash[:alert]).to eq("You are not allowed to confirm another user.")
      end
    end
  end
end