require 'rails_helper'

RSpec.describe PortalStage, type: :model do
  describe do
    it 'should be valid object' do
      expect(build(:portal_stage)).to be_valid
    end
  end
end
