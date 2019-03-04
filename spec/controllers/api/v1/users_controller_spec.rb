require 'rails_helper'
RSpec.describe Api::V1::UsersController, type: :controller do
  before(:each) do
    @user_params = {}
    @client = create :client
    @external_api = create :external_api
    @key = @external_api.generate_key
  end

  describe 'POST /users' do
    context '.authenticate_request' do
      it 'when Api-key missing' do
        request.headers['HTTP_HOST'] = @external_api.domain
        request.headers['Api-key'] = nil
        @user_params = FactoryBot.attributes_for(:user)
        @user_params.store(:erp_id, '105')
        @user_params.store(:role, 'user')
        @user_params.store(:booking_portal_client_id, Client.first)
        expect { post :create, params: { user: @user_params } }.to change { User.count }.by(0)
        res = JSON.parse(response.body)
        expect(res['message']).to eq('Required parameters missing.')
        expect(res['status']).to eq('error')
      end

      it 'when request domain empty' do
        request.headers['HTTP_HOST'] = nil
        request.headers['Api-key'] = @key
        @user_params = FactoryBot.attributes_for(:user)
        @user_params.store(:erp_id, '106')
        @user_params.store(:role, 'user')
        @user_params.store(:booking_portal_client_id, Client.first)
        expect { post :create, params: { user: @user_params } }.to change { User.count }.by(0)
        res = JSON.parse(response.body)
        expect(res['message']).to eq('Required parameters missing.')
        expect(res['status']).to eq('error')
      end

      it 'when domain not registered' do
        request.headers['HTTP_HOST'] = 'http://abcd/v1/booking_details'
        request.headers['Api-key'] = @key
        @user_params = FactoryBot.attributes_for(:user)
        @user_params.store(:erp_id, '107')
        @user_params.store(:role, 'user')
        @user_params.store(:booking_portal_client_id, Client.first)
        expect { post :create, params: { user: @user_params } }.to change { User.count }.by(0)
        res = JSON.parse(response.body)
        expect(res['message']).to eq('Kindly register with our application.')
        expect(res['status']).to eq('error')
      end

      it 'when api key is incorrect' do
        request.headers['HTTP_HOST'] = @external_api.domain
        request.headers['Api-key'] = SecureRandom.hex
        @user_params = FactoryBot.attributes_for(:user)
        @user_params.store(:erp_id, '108')
        @user_params.store(:role, 'user')
        @user_params.store(:booking_portal_client_id, Client.first)
        expect { post :create, params: { user: @user_params } }.to change { User.count }.by(0)
        res = JSON.parse(response.body)
        expect(res['message']).to eq('Incorrect key.')
        expect(res['status']).to eq('error')
      end

      it 'when request is authenticated' do
        request.headers['HTTP_HOST'] = @external_api.domain
        request.headers['Api-key'] = @key
        @user_params = FactoryBot.attributes_for(:user)
        @user_params.store(:erp_id, '108')
        @user_params.store(:role, 'user')
        @user_params.store(:booking_portal_client_id, Client.first)
        expect { post :create, params: { user: @user_params } }.to change { User.count }.by(1)
        expect(response).to have_http_status(201)
      end
    end

    context '.erp_id_present? ' do
      it 'when erp-id present' do
        request.headers['HTTP_HOST'] = @external_api.domain
        request.headers['Api-key'] = @key
        @user_params = FactoryBot.attributes_for(:user)
        @user_params.store(:erp_id, '108')
        @user_params.store(:role, 'user')
        @user_params.store(:booking_portal_client_id, Client.first)
        expect { post :create, params: { user: @user_params } }.to change { User.count }.by(1)
        expect(response).to have_http_status(201)
      end

      it 'when erp-id absent' do
        request.headers['HTTP_HOST'] = @external_api.domain
        request.headers['Api-key'] = @key
        @user_params = FactoryBot.attributes_for(:user)
        @user_params.store(:role, 'user')
        @user_params.store(:booking_portal_client_id, Client.first)
        expect { post :create, params: { user: @user_params } }.to change { User.count }.by(0)
        res = JSON.parse(response.body)
        expect(res['message']).to eq('Erp-id is required.')
        expect(res['status']).to eq('bad_request')
      end
    end

    it 'when saves successfully' do
      request.headers['HTTP_HOST'] = @external_api.domain
      request.headers['Api-key'] = @key
      @user_params = FactoryBot.attributes_for(:user)
      @user_params.store(:erp_id, '108')
      @user_params.store(:role, 'user')
      @user_params.store(:booking_portal_client_id, Client.first)
      expect { post :create, params: { user: @user_params } }.to change { User.count }.by(1)
      expect(response).to have_http_status(201)
    end

    it 'when fails to save' do
      request.headers['HTTP_HOST'] = @external_api.domain
      request.headers['Api-key'] = @key
      @user_params = FactoryBot.attributes_for(:user)
      @user_params.store(:erp_id, '108')
      @user_params.store(:role, 'user')
      expect { post :create, params: { user: @user_params } }.to change { User.count }.by(0)
      expect(response).to have_http_status(422)
    end
  end

  describe 'PATCH /user' do
    context '.set user ' do
      it 'when user with erp-id is present' do
        request.headers['HTTP_HOST'] = @external_api.domain
        request.headers['Api-key'] = @key
        user = create(:user, booking_portal_client: @client, role: 'user', confirmed_at: Time.now)
        user.set(erp_id: '123')
        @user_params = { erp_id: '123', first_name: 'roshi' }
        patch :update, params: { id: user.id, user: @user_params }
        expect(response).to have_http_status(200)
      end

      it 'when user with erp-id not found' do
        request.headers['HTTP_HOST'] = @external_api.domain
        request.headers['Api-key'] = @key
        user = create(:user, booking_portal_client: @client, role: 'user', confirmed_at: Time.now)
        user.set(erp_id: '0001')
        @user_params = { erp_id: '0000', first_name: 'raashi' }
        patch :update, params: { id: user.id, user: @user_params }
        res = JSON.parse(response.body)
        expect(res['message']).to eq('User is not registered.')
        expect(res['status']).to eq('not_found')
      end
    end

    it 'when update successful' do
      request.headers['HTTP_HOST'] = @external_api.domain
      request.headers['Api-key'] = @key
      user = create(:user, booking_portal_client: @client, role: 'user', confirmed_at: Time.now)
      user.set(erp_id: '124')
      @user_params = { erp_id: '124', first_name: 'raashi' }
      patch :update, params: { id: user.id, user: @user_params }
      expect(response).to have_http_status(200)
    end

    it 'when update fails' do
      request.headers['HTTP_HOST'] = @external_api.domain
      request.headers['Api-key'] = @key
      user = create(:user, booking_portal_client: @client, role: 'user', confirmed_at: Time.now)
      user.set(erp_id: '125')
      @user_params = { email: '123****', erp_id: '125' }
      patch :update, params: { id: user.id, user: @user_params }
      expect(response).to have_http_status(422)
    end
  end
end
