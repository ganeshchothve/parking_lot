require 'rails_helper'

RSpec.describe Client, type: :model do
  describe do
    it 'should have a valid factory' do
      expect(build(:client)).to be_valid
    end

    context 'test cases for configure time slot' do
      it 'is invalid without slot_start_date if enable_slot_generation is set to true' do
        @client = create(:client)
        @client.start_time = Time.zone.parse('2019-03-01 10:00')
        @client.end_time = Time.zone.parse('2019-03-03 11:00')
        @client.capacity = 2
        @client.duration = 30
        @client.slot_start_date = nil
        @client.enable_slot_generation = true
        expect(@client.save).to be(false)
        expect(@client.errors[:slot_start_date]).to eq(["can't be blank"])
      end

      it 'is invalid if duration < 1' do
        @client = create(:client)
        @client.start_time = Time.zone.parse('2019-03-01 10:00')
        @client.end_time = Time.zone.parse('2019-03-03 11:00')
        @client.capacity = 2
        @client.slot_start_date = Time.zone.parse('2019-03-01')
        @client.duration = 0
        @client.enable_slot_generation = true
        expect(@client.save).to be(false)
        expect(@client.errors[:duration]).to eq(['must be greater than 0'])
      end

      it 'is invalid without start_time if enable_slot_generation is set to true' do
        @client = create(:client)
        @client.slot_start_date = Time.zone.parse('2019-03-01')
        @client.end_time = Time.zone.parse('2019-03-03 11:00')
        @client.capacity = 2
        @client.duration = 30
        @client.start_time = nil
        @client.enable_slot_generation = true
        expect(@client.save).to be(false)
        expect(@client.errors[:start_time]).to eq(["can't be blank"])
      end

      it 'is invalid without end_time if enable_slot_generation is set to true' do
        @client = create(:client)
        @client.slot_start_date = Time.zone.parse('2019-03-01')
        @client.start_time = Time.zone.parse('2019-03-01 10:00')
        @client.capacity = 2
        @client.duration = 30
        @client.end_time = nil
        @client.enable_slot_generation = true
        expect(@client.save).to be(false)
        expect(@client.errors[:end_time]).to eq(["can't be blank"])
      end

      it 'is invalid without capacity if enable_slot_generation is set to true' do
        @client = create(:client)
        @client.slot_start_date = Time.zone.parse('2019-03-01')
        @client.start_time = Time.zone.parse('2019-03-01 10:00')
        @client.end_time = Time.zone.parse('2019-03-03 11:00')
        @client.duration = 30
        @client.capacity = nil
        @client.enable_slot_generation = true
        expect(@client.save).to be(false)
        expect(@client.errors[:capacity]).to eq(["can't be blank"])
      end

      it 'is invalid without duration if enable_slot_generation is set to true' do
        @client = create(:client)
        @client.slot_start_date = Time.zone.parse('2019-03-01')
        @client.start_time = Time.zone.parse('2019-03-01 10:00')
        @client.end_time = Time.zone.parse('2019-03-03 11:00')
        @client.capacity = 2
        @client.duration = nil
        @client.enable_slot_generation = true
        expect(@client.save).to be(false)
        expect(@client.errors[:duration]).to eq(["can't be blank"])
      end

      it 'is invalid if start_time > end_time' do
        @client1 = create(:client)
        @client1.slot_start_date = Time.zone.parse('2019-03-01')
        @client1.end_time = Time.zone.parse('2019-03-01 10:00')
        @client1.capacity = 2
        @client1.duration = 30
        @client1.start_time = @client1.end_time + 1.seconds
        expect(@client1.save).to be(false)
        expect(@client1.errors[:end_time]).to eq(['End Time must be more than start time.'])
      end

      it 'is invalid if start_time is equal end_time' do
        @client2 = create(:client)
        @client2.slot_start_date = Time.zone.parse('2019-03-01')
        @client2.end_time = Time.zone.parse('2019-03-01 10:00')
        @client2.capacity = 2
        @client2.duration = 30
        @client2.start_time = @client2.end_time
        expect(@client2.save).to be(false)
        expect(@client2.errors[:end_time]).to eq(['End Time must be more than start time.'])
      end

      it 'is invalid if capacity < 1' do
        @client = create(:client)
        @client.slot_start_date = Time.zone.parse('2019-03-01')
        @client.start_time = Time.zone.parse('2019-03-01 10:00')
        @client.end_time = Time.zone.parse('2019-03-03 11:00')
        @client.capacity = 2
        @client.duration = 30
        @client.capacity = 0
        expect(@client.save).to be(false)
        expect(@client.errors[:capacity]).to eq(['must be greater than 0'])
      end

      it 'is invalid if duration is too long for the given time slot' do
        @client = create(:client)
        @client.slot_start_date = Time.zone.parse('2019-03-01')
        @client.start_time = Time.zone.parse('2019-03-01 10:00')
        @client.end_time = Time.zone.parse('2019-03-01 11:00')
        @client.capacity = 2
        @client.duration = 30
        @client.duration = (@client.end_time - @client.start_time) / 60 + 1.seconds
        expect(@client.save).to be(false)
        expect(@client.errors[:duration]).to eq(['Duration is too long to fit a slot in one day.'])
      end

      it 'is a valid object' do
        @client4 = create(:client)
        @client4.slot_start_date = Time.zone.parse('2019-03-01')
        @client4.start_time = Time.zone.parse('2019-03-01 10:00')
        @client4.end_time = Time.zone.parse('2019-03-03 11:00')
        @client4.capacity = 2
        @client4.duration = 30
        @client4.enable_slot_generation = true
        expect(@client4.save).to be(true)
      end
    end
  end
end
