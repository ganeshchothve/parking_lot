require 'rails_helper'
RSpec.describe Admin::ClientsController, type: :controller do
  describe 'client configuration' do
    before(:each) do
      admin = create(:superadmin)
      sign_in_app(admin)
      @user = create(:user)
    end

    describe 'update configuration for time slot' do
      context 'Receipt has not been generated' do
        it 'attributes are editable when enable_slot_generation is true' do
          @client = create(:client)
          @client.start_time = Time.zone.parse('2019-03-01 10:00')
          @client.end_time = Time.zone.parse('2019-03-01 11:00')
          @client.capacity = 2
          @client.duration = 30
          @client.slot_start_date = Time.zone.parse('2019-03-01')
          @client.enable_slot_generation = true
          @client.save
          client_params = { duration: 60 }
          patch :update, params: { client: client_params }
          expect(Client.first.duration).to be(60)
        end

        it 'attributes are not editable when enable_slot_generation is false' do
          @client = create(:client)
          @client.start_time = Time.zone.parse('2019-03-01 10:00')
          @client.end_time = Time.zone.parse('2019-03-01 11:00')
          @client.capacity = 2
          @client.duration = 30
          @client.slot_start_date = Time.zone.parse('2019-03-01')
          @client.enable_slot_generation = true
          @client.save
          @client.enable_slot_generation = false
          @client.save
          client_params = { duration: 60 }
          patch :update, params: { client: client_params }
          expect(@client.duration).to be(30)
        end
      end

      context 'Receipts have been generated' do
        it 'attributes are not editable' do
          @client = create(:client)
          @client.start_time = Time.zone.parse('2019-03-01 10:00')
          @client.end_time = Time.zone.parse('2019-03-01 11:00')
          @client.capacity = 2
          @client.duration = 30
          @client.slot_start_date = Time.zone.parse('2019-03-01')
          @client.enable_slot_generation = true
          @client.save
          @receipt = create(:receipt)
          client_params = { duration: 60 }
          patch :update, params: { client: client_params }
          expect(@client.duration).to be(30)
        end

        it 'enable_slot_generation is editable while it is true' do
          @client = Client.first
          @client.start_time = Time.zone.parse('2019-03-01 10:00')
          @client.end_time = Time.zone.parse('2019-03-01 11:00')
          @client.capacity = 2
          @client.duration = 30
          @client.slot_start_date = Time.zone.parse('2019-03-01')
          @client.enable_slot_generation = true
          @client.save
          @receipt = create(:receipt)
          client_params = { enable_slot_generation: false }
          patch :update, params: { client: client_params }
          expect(Client.find(@client.id).enable_slot_generation).to be(false)
        end

        it 'enable_slot_generation is disabled once it is set to false' do
          @client = create(:client)
          @client.start_time = Time.zone.parse('2019-03-01 10:00')
          @client.end_time = Time.zone.parse('2019-03-01 11:00')
          @client.capacity = 2
          @client.duration = 30
          @client.slot_start_date = Time.zone.parse('2019-03-01')
          @client.enable_slot_generation = true
          @client.save
          @receipt = create(:receipt)
          @client.enable_slot_generation = false
          @client.save
          client_params = { enable_slot_generation: true }
          patch :update, params: { client: client_params }
          expect(@client.enable_slot_generation).to be(false)
        end
      end
    end
  end
end
