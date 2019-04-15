require 'rails_helper'
RSpec.describe Receipt, type: :model do
  describe do
    before(:each) do
      @client = create(:client)
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
  end
end
