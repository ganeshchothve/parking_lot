require 'rails_helper'

RSpec.describe Client, type: :model do
  describe do
    it 'should be valid object' do
      expect( build(:client) ).to be_valid
    end
  end
end