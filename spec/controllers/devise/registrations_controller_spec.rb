require 'rails_helper'
RSpec.describe LocalDevise::RegistrationsController, type: :controller do
  before(:each) do
    @request.env['devise.mapping'] = Devise.mappings[:user]
    create(:project)
    @user1 = create :user
    create(:admin)
    @user_params = FactoryBot.attributes_for(:user)
  end

  describe 'POST /users' do
    it 'when first_name is empty' do
      @user_params[:first_name] = nil
      expect { post :create, params: { user: @user_params } }.to change { User.count }.by(0)
      expect(response.request.flash[:alert][0]).to eq("First name can't be blank")
    end

    it 'when phone and email both are empty' do
      @user_params[:email] = nil
      @user_params[:phone] = nil
      expect { post :create, params: { user: @user_params } }.to change { User.count }.by(0)
      expect(response.request.flash[:alert][0]).to eq('Phone is invalid')
    end

    it 'when email is invalid' do
      @user_params[:email] = 'hjhj'
      expect { post :create, params: { user: @user_params } }.to change { User.count }.by(0)
      expect(response.request.flash[:alert][0]).to eq('Email is invalid')
    end

    it 'when email already exists' do
      @user_params[:email] = @user1.email
      expect { post :create, params: { user: @user_params } }.to change { User.count }.by(0)
      expect(response.request.flash[:alert][0]).to eq('Email is already taken')
    end

    it 'when phone already exists' do
      @user_params[:email] = nil
      @user_params[:phone] = @user1.phone
      expect { post :create, params: { user: @user_params } }.to change { User.count }.by(0)
      expect(response.request.flash[:alert][0]).to eq('Phone is already taken')
    end

    it 'when phone is invalid' do
      @user_params[:email] = nil
      @user_params[:phone] = '5678'
      expect { post :create, params: { user: @user_params } }.to change { User.count }.by(0)
      expect(response.request.flash[:alert][0]).to eq('Phone is invalid')
    end

    it 'when password is invalid' do
      @user_params[:password] = 'a2'
      expect { post :create, params: { user: @user_params } }.to change { User.count }.by(0)
      expect(response.request.flash[:alert][0]).to eq('Password is too short (minimum is 6 characters)')
    end

    context '.set params' do
      it 'when there are extra keys in utm_params' do
        create(:project)
        create(:admin)
        @user_params = FactoryBot.attributes_for(:user)
        request.cookies['utm_params'] = { campaign: 'x', source: 'y', sub_source: 'z', medium: 'a', term: 'b', sample: 'er' }
        expect { post :create, params: { user: @user_params } }.to change { User.count }.by(1)
      end
    end

    it 'when user is registered successfully' do
      create(:project)
      create(:admin)
      @user_params = FactoryBot.attributes_for(:user)
      request.cookies['utm_params'] = { campaign: 'x', source: 'y', sub_source: 'z', medium: 'a', term: 'b' }
      expect { post :create, params: { user: @user_params } }.to change { User.count }.by(1)
    end
  end
end
