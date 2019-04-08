require 'rails_helper'
RSpec.describe Admin::SchemesController, type: :controller do
  let(:client) { create :client }
  let(:user) { create(:user, booking_portal_client: client) }
  let(:admin) { create(:user, booking_portal_client: client) }
  let(:project) { create(:project, booking_portal_client: client) }
  let(:project_tower) { create(:project_tower, project: project) }
  let(:project_unit) { create(:project_unit, project: project, booking_portal_client: client, project_tower: project_tower) }
  describe "check filters for schemes" do
    before (:each) do

      admin.set(role: "admin")
      sign_in_app(admin)
      @scheme1 = create(:scheme, can_be_applied_by: ['admin'], project_tower_id: project_tower.id)
      @scheme2 = create(:scheme, user_role: ['user'], project_tower_id: project_tower.id)
      @scheme3 = create(:scheme, project_tower_id: project_tower.id)
      @scheme4 = create(:scheme, name: 'aakruti', project_tower_id: project_tower.id)
    end
    it "index action" do
      get :index
      expect(assigns(:schemes).count).to eq(Scheme.count)
    end
    it "index action with filter for name" do
      get :index, params: {fltrs: {name: @scheme1.name}}
      expect(assigns(:schemes).count).to eq(Scheme.where(name: @scheme2.name).count)
    end
    it "index action with filter for can_be_applied_by" do
      get :index, params: {fltrs: {can_be_applied_by: @scheme1.can_be_applied_by}}
      expect(assigns(:schemes).count).to eq(Scheme.where(can_be_applied_by: @scheme1.can_be_applied_by).count)
    end
    it "index action with filter for user_role" do
      get :index, params: {fltrs: {user_role: @scheme2.user_role}}
      expect(assigns(:schemes).count).to eq(Scheme.where(user_role: @scheme2.user_role).count)
    end
    it "index action with filter for project_tower" do
      get :index, params: {fltrs: {project_tower: @scheme3.project_tower_id}}
      expect(assigns(:schemes).count).to eq(Scheme.where(project_tower_id: @scheme3.project_tower_id).count)
    end
  end
end