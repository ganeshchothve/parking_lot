require 'rails_helper'

RSpec.describe User, type: :model do
  describe do
    it 'should be valid object' do
      expect( build(:user) ).to be_valid
    end
  end
end