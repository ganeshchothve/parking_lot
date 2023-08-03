require 'rails_helper'

RSpec.describe ParkingSite, type: :model do
  describe 'associations' do
    it 'has many spots' do
      parking_site_spots_assocation = described_class.reflect_on_association(:spots)
      expect(parking_site_spots_assocation.macro).to eq(:has_many)
    end

    it 'has many tickets' do
      expect(described_class.reflect_on_association(:tickets).macro).to eq(:has_many)
    end
  end

  describe 'validations' do
    it 'validates presence of name' do
      should validate_presence_of(:name)
    end

    it 'validates uniqueness of name' do
      should validate_uniqueness_of(:name)
    end

    it 'validates presence of total_spots' do
      should validate_presence_of(:total_spots)
    end

    it 'validates numericality of total_spots greater than 0' do
      should validate_numericality_of(:total_spots).is_greater_than(0)
    end
  end
end