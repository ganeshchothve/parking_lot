require 'rails_helper'
RSpec.describe BookingDetail, type: :model do
  describe 'booking detail controller states' do
    before(:each) do
      @client = create(:client)
      admin = create(:admin)
      # sign_in_app(admin)
      @user = create(:user)
      @booking_detail = book_project_unit(@user, nil, nil, 'hold')
      search = @booking_detail.search
      @project_unit = @booking_detail.project_unit
    end
    it 'moves from under_negotiation to scheme approved when the booking detail scheme is approved' do
      @booking_detail.under_negotiation!
      expect(@booking_detail.reload.status).to eq('scheme_approved')
    end

    it 'moves from under_negotiation to blocked when the booking detail scheme is approved and blocking amount is paid (receipt state is success)' do
      @booking_detail.under_negotiation!
      receipt = create(:receipt, user: @user, booking_detail: @booking_detail, total_amount: @client.blocking_amount, status: 'clearance_pending')
      receipt.success!
      expect(@booking_detail.reload.status).to eq('blocked')
    end
    it 'moves from under_negotiation to booked_tentative when the booking detail scheme is approved and amount paid is more than blocking amount(receipt state is success)' do
      @booking_detail.under_negotiation!
      receipt = create(:receipt, user: @user, booking_detail: @booking_detail, total_amount: @client.blocking_amount, status: 'clearance_pending')
      receipt.success!
      receipt1 = create(:receipt, user: @user, booking_detail: @booking_detail, total_amount: 40_000, status: 'clearance_pending')
      receipt1.success!
      expect(@booking_detail.reload.status).to eq('booked_tentative')
    end
    it 'moves from under_negotiation to blocked when the booking detail scheme is approved and more than blocking amount is paid (one receipt state is success and one is pending) ' do
      @booking_detail.under_negotiation!
      receipt = create(:receipt, user: @user, booking_detail: @booking_detail, total_amount: @client.blocking_amount, status: 'clearance_pending')
      receipt.success!
      receipt1 = create(:receipt, user: @user, booking_detail: @booking_detail, total_amount: 40_000)
      expect(@booking_detail.reload.status).to eq('blocked')
    end
    it 'moves from under_negotiation to scheme approved when the booking detail scheme is approved and more than booking amount is paid (receipt state is success)' do
      @booking_detail.under_negotiation!
      receipt = create(:receipt, user: @user, booking_detail: @booking_detail, total_amount: @client.blocking_amount, status: 'clearance_pending')
      receipt.success!
      receipt1 = create(:receipt, user: @user, booking_detail: @booking_detail, total_amount: @project_unit.booking_price, status: 'clearance_pending')
      receipt1.success!
      expect(@booking_detail.reload.status).to eq('booked_confirmed')
    end
  end

  describe "check price calculator" do
    context "for available units" do
      before(:each) do
        admin = create(:admin)
        @project_unit = create(:project_unit)
        @project_unit.costs << Cost.new(name: 'new_cost', key: 'new_cost',category: 'outside_agreement', absolute_value: 50000)
        @project_unit.costs << Cost.new(name: 'old_cost', key: 'old_cost',category: 'outside_agreement', absolute_value: 100000)
        @project_unit.costs << Cost.new(name: 'cost_a', key: 'cost_a', category: 'agreement', absolute_value: 20000)
        @project_unit.costs << Cost.new(name: 'cost_b', key: 'cost_b', category: 'agreement', absolute_value: 40000)
        @booking_detail = BookingDetail.new(name: @project_unit.name, base_rate: @project_unit.base_rate, floor_rise: @project_unit.floor_rise, saleable: @project_unit.saleable, costs: @project_unit.costs, data: @project_unit.data, project_unit: @project_unit )
        @booking_detail_scheme = BookingDetailScheme.new(booking_detail: @booking_detail, project_unit: @project_unit)
        @booking_detail.booking_detail_scheme = @booking_detail_scheme
      end

      context "for calculated costs" do
        it "returns hash of key and value attribute" do
          expect( @booking_detail.calculated_costs[:new_cost]).to eq(50000.0)
          expect(@booking_detail.calculated_costs[:old_cost]).to eq(100000.0)
        end
      end

      context "for calculated cost of new_cost" do
        it "returns value of the cost" do
          expect(@booking_detail.calculated_cost('new_cost')).to eq(@project_unit.costs.where(name: 'new_cost').first.value)
        end
      end

      context "for effective rate when payment adjustments are not present" do
        it "should return sum of base rate and floor rise" do
          expect(@booking_detail.effective_rate).to eq(@project_unit.base_rate + @project_unit.floor_rise)
        end
      end

      context "for effective rate with payment adjustments" do
        it "shoud make payment adjustments to effective rate" do
          @booking_detail_scheme.payment_adjustments << FactoryBot.build(:payment_adjustment,field: 'base_rate', absolute_value: 10000)
          _effective_rate = @project_unit.base_rate + @project_unit.floor_rise
          @booking_detail_scheme.payment_adjustments.in(field: ["base_rate", "floor_rise"]).each do |adj|
            _effective_rate += adj.value self
          end
          expect(@booking_detail.effective_rate).to eq(_effective_rate)
        end
      end


      context "for total agreement costs" do
        it "should return sum of all the costs in agreement category" do
          expect(@booking_detail.total_agreement_costs).to eq(60000.0)
        end
      end

      context "for total outside agreement costs" do
        it "should return sum of all the costs without agreement category" do
          expect(@booking_detail.total_outside_agreement_costs).to eq(150000.0)
        end
      end

      context "for base price" do
        it "should return base_rate * effective_rate" do
          expect(@booking_detail.base_price).to eq(@booking_detail.effective_rate * @booking_detail.saleable)
        end
      end

      context "for calculate agreement price" do
        context "without payment_adjustments" do
          it "should return base_price + total_agreement_costs" do
            _agreement_price = @booking_detail.base_price + 60000
            expect(@booking_detail.calculate_agreement_price).to eq(_agreement_price)
          end
        end

        context "with payment_adjustments" do
          it "should return value adjusted accordingly" do
            @booking_detail_scheme.payment_adjustments << FactoryBot.build(:payment_adjustment,field: 'agreement_price', absolute_value: 10000)
            _agreement_price = @booking_detail.base_price + 70000
            expect(@booking_detail.calculate_agreement_price).to eq(_agreement_price)
          end
        end
      end

      context "for calculate_all_inclusive_price" do
        context "without payment_adjustments" do
          it " should return calculate_agreement_price + total_outside_agreement_costs" do
            _all_inclusive_price = @booking_detail.calculate_agreement_price + @booking_detail.total_outside_agreement_costs
            expect(@booking_detail.calculate_all_inclusive_price).to eq(_all_inclusive_price)
          end
        end
      end
    end
  end

  context "for booked units" do
    before(:each) do
      admin = create(:admin)
      @user = create(:user)
      @project_unit = create(:project_unit)
      @booking_detail = BookingDetail.create(name: @project_unit.name, base_rate: @project_unit.base_rate, floor_rise: @project_unit.floor_rise, saleable: @project_unit.saleable, costs: @project_unit.costs, data: @project_unit.data, project_unit: @project_unit, user_id: @user.id)
      @booking_detail_scheme = BookingDetailScheme.create(booking_detail: @booking_detail, project_unit: @project_unit)
      @booking_detail.booking_detail_scheme = @booking_detail_scheme
    end

    context "for pending balance" do
      context "without receipts on booking detail" do
        it "should return complete booking price" do
          expect(@booking_detail.pending_balance).to eq(@project_unit.booking_price)
        end
      end

      context "with receipts on booking_detail" do
        it "should reduce the amount of receipt" do
          receipt_1 = FactoryBot.create(:receipt, status: 'pending', booking_detail: @booking_detail, user_id: @user.id)
          receipt_2 = FactoryBot.create(:receipt, status: 'clearance_pending', booking_detail: @booking_detail, user_id: @user.id)
          receipt_3 = FactoryBot.create(:receipt, status: 'success', booking_detail: @booking_detail, user_id: @user.id)
          _pending_balance = @project_unit.booking_price - receipt_2.total_amount - receipt_3.total_amount
          expect(@booking_detail.pending_balance({user_id: @user.id})).to eq(_pending_balance.to_i)
          _pending_balance_strict = @project_unit.booking_price - receipt_3.total_amount
          expect(@booking_detail.pending_balance({user_id: @user.id, strict: true})).to eq(_pending_balance_strict.to_i)
        end
      end
    end
  end
end