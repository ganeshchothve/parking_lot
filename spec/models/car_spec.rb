require 'rails_helper'

RSpec.describe Car, type: :model do

  describe 'associations' do
    it 'has one ticket' do
      should have_one(:ticket)
    end
  end

  describe 'validations' do
    it 'validates presence of reg_no' do
      should validate_presence_of(:reg_no)
    end

    it 'validates uniqueness of reg_no (case-insensitive)' do
      should validate_uniqueness_of(:reg_no).case_insensitive
    end

    it 'validates presence of color' do
      should validate_presence_of(:color)
    end

    it 'validates inclusion of color in COLORS' do
      should validate_inclusion_of(:color).in_array(Car::COLORS)
    end
  end
end
