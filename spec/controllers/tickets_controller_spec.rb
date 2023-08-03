# spec/controllers/tickets_controller_spec.rb
require 'rails_helper'

RSpec.describe TicketsController, type: :controller do
  describe 'GET #new' do
    context 'when parking sites are available' do
      let(:parking_site) { create(:parking_site, { name: 'Abhyudaya-East', total_spots: '8' }) }

      it 'renders the new template' do
        get :new
        expect(response).to render_template(:new)
      end
    end

    context 'when no parking sites are available' do
      it 'redirects to the root path with an alert' do
        get :new
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Parking Sites Not Found')
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'POST #create' do
    let!(:parking_site) { create(:parking_site) }

    context 'when a spot is available for the selected parking site and color' do
      let!(:spot) { create(:spot, parking_site: parking_site, status: 'available') }
      let(:car_attributes) { attributes_for(:car) }
      let(:valid_params) { attributes_for(:ticket, parking_site_id: parking_site.id, car_attributes: car_attributes) }

      it 'creates a new ticket and moves the spot to blocked' do
        post :create, params: { ticket: valid_params }
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq('Parking Spot Registered Successfully.')
        expect(response).to have_http_status(:ok)

        created_ticket = Ticket.last
        expect(created_ticket.status).to eq('active')
        expect(created_ticket.spot).to eq(spot.reload)
        expect(spot.reload.status).to eq('blocked')
      end
    end

    context 'when a spot is not available for the selected parking site and color' do
      let(:car_attributes) { attributes_for(:car) }
      let(:invalid_params) { attributes_for(:ticket, parking_site_id: parking_site.id, car_attributes: car_attributes) }

      it 'redirects to the new ticket path with an alert' do
        post :create, params: { ticket: invalid_params }
        expect(response).to redirect_to(new_ticket_path)
        expect(flash[:alert]).to eq('Sorry, Spot for this parking site is not available')
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
