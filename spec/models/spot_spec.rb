require 'rails_helper'

RSpec.describe Spot, type: :model do
  describe 'associations' do
    it 'belongs to parking site' do
      should belong_to(:parking_site)
    end
  end

  describe 'validations' do
    it 'validates inclusion of status in SPOT_STATUSES' do
      should validate_inclusion_of(:status).in_array(Spot::SPOT_STATUSES)
    end

    it 'validates numericality of spot_number greater than 0' do
      should validate_numericality_of(:spot_number).is_greater_than(0)
    end
  end
end
