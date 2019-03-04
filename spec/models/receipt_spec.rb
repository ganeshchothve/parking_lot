require 'rails_helper'

RSpec.describe Receipt, type: :model do
  describe do
    before(:each) do
      @client = create(:client)
      @admin = create(:admin)
      @user = create(:user)
    end

    it 'should have a valid factory' do
      expect(build(:receipt, user: @user)).to be_valid
    end

    describe '#issuing bank' do
      it 'is invalid if contains number' do
        receipt = build(:receipt, user: @user, issuing_bank: 'ABC123 def', payment_mode: 'cheque')
        expect(receipt).to_not be_valid
        expect(receipt.errors.messages[:issuing_bank]).to eq ['can contain only alphabets and spaces']
      end

      it 'is invalid if contains special characters' do
        receipt = build(:receipt, user: @user, issuing_bank: '@#$hjk', payment_mode: 'cheque')
        expect(receipt).to_not be_valid
        expect(receipt.errors.messages[:issuing_bank]).to eq ['can contain only alphabets and spaces']
      end

      it 'is invalid if blank' do
        receipt = build(:receipt, user: @user, issuing_bank: '  ', payment_mode: 'cheque')
        expect(receipt).to_not be_valid
        expect(receipt.errors.messages[:issuing_bank]).to eq ["can't be blank"]
      end

      it 'is valid' do
        receipt = build(:receipt, user: @user, issuing_bank: ' ABC def')
        expect(receipt).to be_valid
      end
    end

    describe '#issuing bank branch' do
      it 'is invalid if contains numbers' do
        receipt = build(:receipt, user: @user, issuing_bank_branch: 'ABC123 def', payment_mode: 'cheque')
        expect(receipt).to_not be_valid
        expect(receipt.errors.messages[:issuing_bank_branch]).to eq ['can contain only alphabets and spaces']
      end

      it 'is invalid if contains special characters' do
        receipt = build(:receipt, user: @user, issuing_bank_branch: '@#$hjk', payment_mode: 'cheque')
        expect(receipt).to_not be_valid
        expect(receipt.errors.messages[:issuing_bank_branch]).to eq ['can contain only alphabets and spaces']
      end

      it 'is invalid if blank' do
        receipt = build(:receipt, user: @user, issuing_bank_branch: '  ', payment_mode: 'cheque')
        expect(receipt).to_not be_valid
        expect(receipt.errors.messages[:issuing_bank_branch]).to eq ["can't be blank"]
      end

      it 'is valid' do
        receipt = build(:receipt, user: @user, issuing_bank_branch: ' ABC def')
        expect(receipt).to be_valid
      end
    end

    describe '#payment_identifier' do
      it 'is invalid if contains special characters' do
        receipt = build(:receipt, user: @user, payment_identifier: 'ABC12*** def', payment_mode: 'cheque')
        expect(receipt).to_not be_valid
        expect(receipt.errors.messages[:payment_identifier]).to eq ['can contain only alphabets, numbers and spaces']
      end

      it 'is invalid if blank' do
        receipt = build(:receipt, user: @user, payment_identifier: '  ', payment_mode: 'cheque')
        expect(receipt).to_not be_valid
        expect(receipt.errors.messages[:payment_identifier]).to eq ["can't be blank"]
      end

      it 'is valid' do
        receipt = build(:receipt, user: @user, payment_identifier: 'ABC12 def')
        expect(receipt).to be_valid
      end
    end

    describe '#issued date' do
      it 'is invalid if blank and payment mode not online' do
        receipt = build(:receipt, user: @user, issued_date: '  ', payment_mode: 'card_swipe')
        expect(receipt).to_not be_valid
        expect(receipt.errors.messages[:issued_date]).to eq ["can't be blank"]
      end

      it 'is invalid if in the future' do
        receipt = build(:receipt, user: @user, issued_date: Time.now + 1.day, payment_mode: 'card_swipe')
        expect(receipt).to_not be_valid
        expect(receipt.errors.messages[:issued_date]).to eq ['should be less than or equal to the current date']
      end

      it 'is valid' do
        receipt = build(:receipt, user: @user, issued_date: Time.now, payment_mode: 'card_swipe')
        expect(receipt).to be_valid
      end

      context do
        [(Time.now - 1.day).to_s, Time.now.to_s, (Time.now + 1.day).to_s].each do |date|
          it 'is valid' do
            receipt = build(:receipt, user: @user, issued_date: date, payment_mode: 'cheque')
            expect(receipt).to be_valid
          end
        end
      end
    end

    describe '#processed on' do
      it 'is invalid if less than issued date' do
        receipt = build(:receipt, user: @user, processed_on: Time.now - 1.day, issued_date: Time.now, payment_mode: 'cheque', status: 'success')
        expect(receipt).to_not be_valid
        expect(receipt.errors.messages[:processed_on]).to eq ['cannot be older than the Issued Date']
      end

      it 'is invalid if in the future' do
        receipt = build(:receipt, user: @user, processed_on: Time.now + 1.day, issued_date: Time.now, payment_mode: 'cheque', status: 'success')
        expect(receipt).to_not be_valid
        expect(receipt.errors.messages[:processed_on]).to eq ['cannot be in the future']
      end

      it 'is valid' do
        receipt = build(:receipt, user: @user, processed_on: Time.now, issued_date: Time.now - 1.day, payment_mode: 'cheque', status: 'success', tracking_id: 'DFGHJ45678')
        expect(receipt).to be_valid
      end
    end

    describe 'time slot generation' do

      it 'should have token number starting from 451' do
        @receipt = create(:receipt)
        expect(@receipt.token_number).to be(451)
      end

      it 'should generate time slot if enable time slot is true' do
        @client1 = Client.first
        @client1.start_time = Time.zone.parse('2019-03-01 10:00')
        @client1.end_time = Time.zone.parse('2019-03-01 11:00')
        @client1.capacity = 2
        @client1.duration = 30
        @client1.slot_start_date = Time.zone.parse('2019-03-01')
        @client1.enable_slot_generation = true
        @client1.save
        @receipt = create(:receipt)
        @receipt.update(status: "success")
        expect(@receipt.time_slot.present?).to be(true)
      end

      it 'should not generate time slot if enable time slot is false' do
        @client2 = Client.first
        @client2.start_time = Time.zone.parse('2019-03-01 10:00')
        @client2.end_time = Time.zone.parse('2019-03-01 11:00')
        @client2.capacity = 2
        @client2.duration = 30
        @client2.slot_start_date = Time.zone.parse('2019-03-01')
        @client2.enable_slot_generation = false
        @client2.save
        @receipt2 = create(:receipt)
        @receipt2.update(status: "success")
        expect(@receipt2.time_slot.present?).to be(false)
      end

      it 'should generate time slot if receipt status is success or clearance pending' do
        @client1 = Client.first
        @client1.start_time = Time.zone.parse('2019-03-01 10:00')
        @client1.end_time = Time.zone.parse('2019-03-01 11:00')
        @client1.capacity = 2
        @client1.duration = 30
        @client1.slot_start_date = Time.zone.parse('2019-03-01')
        @client1.enable_slot_generation = true
        @client1.save
        @receipt4 = create(:receipt)
        @receipt4.update(status: "success")
        @receipt5 = create(:receipt)
        @receipt5.update(status: "clearance_pending")
        expect(@receipt4.time_slot.present?).to be(true)
        expect(@receipt5.time_slot.present?).to be(true)
      end

      it 'should not generate time slot if receipt status is not success clearance pending' do
        @client1 = Client.first
        @client1.start_time = Time.zone.parse('2019-03-01 10:00')
        @client1.end_time = Time.zone.parse('2019-03-01 11:00')
        @client1.capacity = 2
        @client1.duration = 30
        @client1.slot_start_date = Time.zone.parse('2019-03-01')
        @client1.enable_slot_generation = true
        @client1.save
        @receipt6 = create(:receipt)
        @receipt6.update(status: "pending")
        @receipt7 = create(:receipt)
        @receipt7.update(status: "cancelled")
        expect(@receipt6.time_slot.present?).to be(false)
        expect(@receipt7.time_slot.present?).to be(false)
      end

      context 'calculate time slot Case 1' do
        before(:each) do
          @client3 = Client.first
          @client3.start_time = Time.zone.parse('2019-03-05 10:00')
          @client3.end_time = Time.zone.parse('2019-03-05 11:00')
          @client3.capacity = 2
          @client3.duration = 30
          @client3.slot_start_date = Time.zone.parse('2019-03-05')
          @client3.enable_slot_generation = true
          @client3.save
        end

        it 'token number 1, 2' do
          @receipt10 = create(:receipt)
          @receipt10.set(token_number: 1)
          @receipt10.update(status: "success")
          @receipt11 = create(:receipt)
          @receipt11.set(token_number: 2)
          @receipt11.update(status: "success")
          @receipt10.time_slot.start_time.strftime("%I:%M %p").should eql("10:00 AM")
          @receipt10.time_slot.end_time.strftime("%I:%M %p").should eql("10:30 AM")
          @receipt10.time_slot.date.strftime('%d/%m/%Y').should eql("05/03/2019")
          @receipt11.time_slot.start_time.strftime("%I:%M %p").should eql("10:00 AM")
          @receipt11.time_slot.end_time.strftime("%I:%M %p").should eql("10:30 AM")
          @receipt11.time_slot.date.strftime('%d/%m/%Y').should eql("05/03/2019")
        end

        it 'token number 3, 4' do
          @receipt12 = create(:receipt)
          @receipt12.set(token_number: 3)
          @receipt12.update(status: "success")
          @receipt13 = create(:receipt)
          @receipt13.set(token_number: 4)
          @receipt13.update(status: "success")
          @receipt12.time_slot.start_time.strftime("%I:%M %p").should eql("10:30 AM")
          @receipt12.time_slot.end_time.strftime("%I:%M %p").should eql("11:00 AM")
          @receipt12.time_slot.date.strftime('%d/%m/%Y').should eql("05/03/2019")
          @receipt13.time_slot.start_time.strftime("%I:%M %p").should eql("10:30 AM")
          @receipt13.time_slot.end_time.strftime("%I:%M %p").should eql("11:00 AM")
          @receipt13.time_slot.date.strftime('%d/%m/%Y').should eql("05/03/2019")
        end

        it 'token number 5' do
          @receipt14 = create(:receipt)
          @receipt14.set(token_number: 5)
          @receipt14.update(status: "success")
          @receipt14.time_slot.start_time.strftime("%I:%M %p").should eql("10:00 AM")
          @receipt14.time_slot.end_time.strftime("%I:%M %p").should eql("10:30 AM")
          @receipt14.time_slot.date.strftime('%d/%m/%Y').should eql("06/03/2019")
        end
      end

      context 'calculate time slot Case 2' do
        before(:each) do
          @client4 = Client.first
          @client4.start_time = Time.zone.parse('2019-03-05 10:00')
          @client4.end_time = Time.zone.parse('2019-03-05 11:00')
          @client4.capacity = 1
          @client4.duration = 45
          @client4.slot_start_date = Time.zone.parse('2019-03-05')
          @client4.enable_slot_generation = true
          @client4.save
        end

        it 'token number 6, 7' do
          @receipt15 = create(:receipt)
          @receipt15.set(token_number: 6)
          @receipt15.update(status: "success")
          @receipt16 = create(:receipt)
          @receipt16.set(token_number: 7)
          @receipt16.update(status: "success")
          @receipt15.time_slot.start_time.strftime("%I:%M %p").should eql("10:00 AM")
          @receipt15.time_slot.end_time.strftime("%I:%M %p").should eql("10:45 AM")
          @receipt15.time_slot.date.strftime('%d/%m/%Y').should eql("10/03/2019")
          @receipt16.time_slot.start_time.strftime("%I:%M %p").should eql("10:00 AM")
          @receipt16.time_slot.end_time.strftime("%I:%M %p").should eql("10:45 AM")
          @receipt16.time_slot.date.strftime('%d/%m/%Y').should eql("11/03/2019")
        end
      end

      context 'calculate time slot Case 3' do
        before(:each) do
          @client5 = Client.first
          @client5.start_time = Time.zone.parse('2019-03-05 10:00')
          @client5.end_time = Time.zone.parse('2019-03-05 11:00')
          @client5.capacity = 2
          @client5.duration = 45
          @client5.slot_start_date = Time.zone.parse('2019-03-05')
          @client5.enable_slot_generation = true
          @client5.save
        end

        it 'token number 8, 9' do
          @receipt16 = create(:receipt)
          @receipt16.set(token_number: 8)
          @receipt16.update(status: "success")
          @receipt17 = create(:receipt)
          @receipt17.set(token_number: 9)
          @receipt17.update(status: "success")
          @receipt16.time_slot.start_time.strftime("%I:%M %p").should eql("10:00 AM")
          @receipt16.time_slot.end_time.strftime("%I:%M %p").should eql("10:45 AM")
          @receipt16.time_slot.date.strftime('%d/%m/%Y').should eql("08/03/2019")
          @receipt17.time_slot.start_time.strftime("%I:%M %p").should eql("10:00 AM")
          @receipt17.time_slot.end_time.strftime("%I:%M %p").should eql("10:45 AM")
          @receipt17.time_slot.date.strftime('%d/%m/%Y').should eql("09/03/2019")
        end
      end

      context 'update time slot' do
        before(:each) do
          @client6 = Client.first
          @client6.start_time = Time.zone.parse('2019-03-01 10:00')
          @client6.end_time = Time.zone.parse('2019-03-01 11:00')
          @client6.capacity = 2
          @client6.duration = 45
          @client6.slot_start_date = Time.zone.parse('2019-03-01')
          @client6.enable_slot_generation = true
          @client6.save
        end

        it 'time slot not available' do
          @receipt16 = create(:receipt)
          @receipt16.set(token_number: 11)
          @receipt16.update(status: "success")
          @receipt17 = create(:receipt)
          @receipt17.update(status: "success")
          @receipt17.token_number = 11
          expect(@receipt17.save).to be(false)
          expect(@receipt17.errors[:token_number]).to eq(['Time Slot for this token number is not available.'])
        end

        it 'time slot in the past' do
          @receipt18 = create(:receipt)
          @receipt18.set(token_number: 12)
          @receipt18.update(status: "success")
          @receipt18.token_number = 1
          expect(@receipt18.save).to be(false)
          expect(@receipt18.errors[:token_number]).to eq(['Time Slot for this token number is in the past.'])
        end

        it 'time slot available' do
          @receipt19 = create(:receipt)
          @receipt19.set(token_number: 15)
          @receipt19.update(status: "success")
          @receipt19.token_number = 16
          expect(@receipt19.save).to be(true)
          @receipt19.token_number.should eql(16)
        end

        it 'token number updated to nil, time slot also becomes nil ' do
          @receipt21 = create(:receipt)
          @receipt21.update(status: "success")
          @receipt21.update(token_number: nil)
          expect(@receipt21.time_slot.present?).to be(false)
        end

        it 'token number was nil and changed to 20' do
          @receipt20 = create(:receipt)
          @receipt20.update(status: "success")
          @receipt20.set(token_number: nil)
          @receipt20.set(time_slot: nil)
          @receipt20.token_number = 20
          expect(@receipt20.save).to be(true)
          expect(@receipt20.time_slot.present?).to be(true)
        end
      end

      context 'update other attributes' do
        before(:each) do
          @client7 = Client.first
          @client7.start_time = Time.zone.parse('2019-03-05 10:00')
          @client7.end_time = Time.zone.parse('2019-03-05 11:00')
          @client7.capacity = 2
          @client7.duration = 45
          @client7.slot_start_date = Time.zone.parse('2019-03-05')
          @client7.enable_slot_generation = true
          @client7.save
        end

        it 'token number present and not changed' do
          @receipt50 = create(:receipt)
          @receipt50.set(token_number: 50)
          @receipt50.update(status: "success")
          @receipt50.save
          t = @receipt50.time_slot
          @receipt50.update(comments: "heyy")
          @receipt50.save
          expect(@receipt50.time_slot).to be(t)
        end

        it 'token number nil and not changed' do
          @receipt50 = create(:receipt)
          @receipt50.update(status: "success")
          @receipt50.save
          @receipt50.set(token_number: nil)
          @receipt50.set(time_slot: nil)
          @receipt50.update(comments: "hii")
          @receipt50.save
          expect(@receipt50.time_slot.present?).to be(false)
        end
      end
    end
  end
end
