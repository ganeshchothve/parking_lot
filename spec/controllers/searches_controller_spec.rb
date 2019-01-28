require 'rails_helper'

RSpec.describe SearchesController, type: :controller do
  let(:client) { create :client }
  let(:user) { create(:user, booking_portal_client: client) }
  let(:admin) { create(:user, booking_portal_client: client) }
  let(:project) { create(:project, booking_portal_client: client) }
  let(:project_tower) { create(:project_tower, project: project) }
  let(:project_unit) { create(:project_unit, project: project, booking_portal_client: client, project_tower: project_tower) }
  let(:search) { create(:search, project_unit_id: project_unit.id.to_s, user: user) }

  before(:each) do
    admin.set(role: "admin")
    sign_in_app(user)
  end

  describe 'HOLD' do
    it 'throws error when user has not completed his or her kyc' do
      project_unit.client_id = Client.first
      project_unit.user = user
      post :hold, params: { id: search.id, project_unit: project_unit.as_json }
      expect(response.request.flash[:error]).to eq('The user is not confirmed or kyc documents are not uploaded.')
    end
    it 'throws error when the unit is already held' do
      client.allow_multiple_bookings_per_user_kyc = false
      client.save
      user.booking_portal_client = client
      user.user_kycs << create(:user_kyc, creator_id: user.id, user: user)
      user.save
      project_unit.client_id = client.id
      project_unit.user = user
      project_unit.primary_user_kyc_id = user.user_kycs.first.id
      project_unit.status = 'hold'
      project_unit.save
      another_user = create(:user, booking_portal_client: client)
      another_user.user_kycs << create(:user_kyc, creator_id: another_user.id, user: another_user)
      search.user = another_user
      post :hold, params: { id: search.id, project_unit: project_unit.as_json }
      expect(response.request.flash[:error]).to eq('This unit is already held by other user.')
    end
    it 'throws error when user has reached max allowed bookings' do
      user.set(allowed_bookings: 0)
      project_unit.client_id = Client.first
      user.booking_portal_client ||= (Client.asc(:created_at).first || create(:client))
      user.user_kycs << create(:user_kyc, creator_id: user.id, user: user)
      project_unit.user = user
      post :hold, params: { id: search.id, project_unit: project_unit.as_json }
      expect(response.request.flash[:error]).to eq('You have booked the permitted number of apartments.')
    end
    it 'throws error when user does not have unused kyc id ' do
      client.allow_multiple_bookings_per_user_kyc = false
      client.save
      user.booking_portal_client = client
      user.user_kycs << create(:user_kyc, creator_id: user.id, user: user, phone: '9753736524')
      user.save
      project_unit.client_id = client.id
      project_unit.user = user
      project_unit.primary_user_kyc_id = user.user_kycs.first.id
      project_unit.status = 'blocked'
      project_unit.save
      another_project_unit = create(:project_unit, project: project, booking_portal_client: client, project_tower: project_tower)
      another_project_unit.user = user
      search.project_unit_id = another_project_unit.id
      search.save
      post :hold, params: { id: search.id, project_unit: another_project_unit.as_json }
      expect(response.request.flash[:error]).to eq('You can book only one unit on one KYC.')
    end
  end
end
