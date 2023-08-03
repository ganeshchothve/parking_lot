require 'rails_helper'

RSpec.describe Ticket, type: :model do
  describe 'associations' do
    it 'belongs to spot' do
      should belong_to(:spot)
    end

    it 'belongs to parking site' do
      should belong_to(:parking_site)
    end

    it 'belongs to car' do
      should belong_to(:car)
    end
  end

  describe 'validations' do
    it 'validates inclusion of status in TICKET_STATUSES' do
      should validate_inclusion_of(:status).in_array(Ticket::TICKET_STATUSES)
    end
  end
end