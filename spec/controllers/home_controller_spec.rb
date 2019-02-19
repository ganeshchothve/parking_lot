require 'rails_helper'
RSpec.describe HomeController, type: :controller do
  before(:each) do
    create(:project)
    create(:admin)
    @user_params = FactoryBot.attributes_for(:user)
  end

  describe 'POST /check_and_register' do
    it 'when extra utm_params are present' do
      request.cookies['utm_params'] = { campaign: 'x', source: 'y', sub_source: 'z', medium: 'a', term: 'b', sample: 'er' }
      expect { post :check_and_register, xhr: true, params: @user_params }.to change { User.count }.by(1)
    end
  end
end
