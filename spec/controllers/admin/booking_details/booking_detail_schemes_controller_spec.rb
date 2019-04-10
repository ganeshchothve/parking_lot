require 'rails_helper'
RSpec.describe Admin::BookingDetails::BookingDetailSchemesController, type: :controller do
  before(:each) do 
    @client = Client.first || create(:client)
    @admin = create(:admin)
    @user = create(:user)
    sign_in_app(@admin)
  end
  describe 'Admin side' do
    describe "normal scenario (when payment adjustment is not added )" do 
      before(:each) do 
        kyc = create(:user_kyc, creator_id: @user.id, user: @user)
      @project_unit = create(:project_unit, status: 'hold', user: @user, primary_user_kyc_id: kyc.id)
      @search = create(:search, project_unit_id: @project_unit.id, user: @user)
      @booking_detail = create(:booking_detail, primary_user_kyc_id: @project_unit.primary_user_kyc_id, project_unit_id: @project_unit.id, user_id: @user.id)
        booking_detail_scheme_params = FactoryBot.attributes_for(:booking_detail_scheme)
        booking_detail_scheme_params[:derived_from_scheme_id] = Scheme.first.id
        post :create, params: { booking_detail_scheme: booking_detail_scheme_params, user_id: @user.id, booking_detail_id: @project_unit.booking_detail.id }
        @booking_detail_scheme = BookingDetailScheme.first
        @booking_detail.under_negotiation!
      end
      it 'booking_detail_scheme is created for every booking' do
        expect(@booking_detail_scheme.booking_detail.id).to eq(@project_unit.booking_detail.id)
      end
      it 'booking_detail goes to scheme approved when booking_detail_scheme has no payment adjusments' do 
        expect(@booking_detail.status).to eq('scheme_approved')
      end
    end

    describe "booking_detail_scheme is approved" do 
      before(:each) do 
        @booking_detail = booking_under_negotiation(@user)
        @booking_detail_scheme = @booking_detail.booking_detail_scheme
        patch :update,params: {id: @booking_detail_scheme.id, booking_detail_id: @booking_detail.id, booking_detail_scheme: {event: 'approved'}}
      end
      it "booking_detail_scheme status changes to approved" do
        expect(@booking_detail_scheme.reload.status).to eq ('approved')
      end
      it "booking_detail changes status to scheme_approved" do
        expect(@booking_detail.reload.status).to eq ('scheme_approved')
      end
    end
    describe "booking_detail_scheme is updated" do 
      before(:each) do 
        @booking_detail = booking_under_negotiation(@user)
        @booking_detail_scheme = @booking_detail.booking_detail_scheme
        @booking_detail_scheme.reload.approved!
        # reload is needed, reason yet to be figured out
      end
      describe "derived_scheme is changed" do 
        before(:each) do 
          @scheme = create(:scheme)
          patch :update,params: {id: @booking_detail_scheme.id, booking_detail_id: @booking_detail.id, booking_detail_scheme: {derived_from_scheme_id: @scheme.id }}
        end
        it "booking_detail_scheme goes to draft from approved" do
          expect(@booking_detail_scheme.reload.status).to eq('draft')
        end
        it "booking_detail_scheme derived_from_scheme changes" do 
          expect(@booking_detail_scheme.reload.derived_from_scheme_id).to eq(@scheme.id)
        end
        it "scheme's payment_adjustments are attached to the booking_detail_scheme" do 
          expect(@booking_detail_scheme.reload.payment_adjustments.pluck(:name)).to match_array(@scheme.payment_adjustments.pluck(:name))
        end
      end
      describe  "new payment_adjustment is added to approved booking_detail_scheme " do
        before(:each) do 
          @payment_adjustments_params = FactoryBot.attributes_for(:payment_adjustment)
          
        end
        it "booking_detail_scheme goes to draft from approved" do
          patch :update,params: {id: @booking_detail_scheme.id, booking_detail_id: @booking_detail.id, booking_detail_scheme: {payment_adjustments_attributes: {"1233": @payment_adjustments_params}}}
          expect(@booking_detail_scheme.reload.status).to eq ('draft')
        end
        it "booking_detail goes from scheme_approved to under_negotiation" do 
          patch :update,params: {id: @booking_detail_scheme.id, booking_detail_id: @booking_detail.id, booking_detail_scheme: {payment_adjustments_attributes: {"1233": @payment_adjustments_params}}}
          expect(@booking_detail.reload.status).to eq('under_negotiation')
        end
        it "booking_detail goes from blocked to under_negotiation" do
          receipt = create(:receipt, user: @user, project_unit: @project_unit, booking_detail: @booking_detail, total_amount: @client.blocking_amount)
          receipt.clearance_pending!
          patch :update,params: {id: @booking_detail_scheme.id, booking_detail_id: @booking_detail.id, booking_detail_scheme: {payment_adjustments_attributes: {"1233": @payment_adjustments_params}}}
          expect(@booking_detail.reload.status).to eq('under_negotiation')
        end
        it "booking_detail goes from booked_tentative to under_negotiation" do 
          receipt = create(:receipt, user: @user, project_unit: @project_unit, booking_detail: @booking_detail, total_amount: @client.blocking_amount)
          receipt.clearance_pending!
          receipt1 = create(:receipt, user: @user, project_unit: @project_unit, booking_detail: @booking_detail, total_amount: 40_000)
          receipt1.clearance_pending!
          patch :update,params: {id: @booking_detail_scheme.id, booking_detail_id: @booking_detail.id, booking_detail_scheme: {payment_adjustments_attributes: {"1233": @payment_adjustments_params}}}
          expect(@booking_detail.reload.status).to eq('under_negotiation')
        end
        it "booking_detail goes from booked_confirmed to under_negotiation" do 
          receipt = create(:receipt, user: @user, project_unit: @project_unit, booking_detail: @booking_detail, total_amount: @client.blocking_amount)
          receipt.clearance_pending!
          receipt1 = create(:receipt, user: @user, project_unit: @project_unit, booking_detail: @booking_detail, total_amount: 40_000)
          receipt1.clearance_pending!
          receipt2 = create(:receipt, user: @user, project_unit: @project_unit, booking_detail: @booking_detail, total_amount: 40_000)
          receipt2.clearance_pending!
          patch :update,params: {id: @booking_detail_scheme.id, booking_detail_id: @booking_detail.id, booking_detail_scheme: {payment_adjustments_attributes: {"1233": @payment_adjustments_params}}}
          expect(@booking_detail.reload.status).to eq('under_negotiation')
        end
      end
    end

    describe "scheme is rejected " do 
      before(:each) do 
        @booking_detail = booking_under_negotiation(@user)
        @booking_detail_scheme = @booking_detail.booking_detail_scheme
        receipt = create(:receipt, user: @user, project_unit: @project_unit, booking_detail: @booking_detail, total_amount: @client.blocking_amount)
        receipt.clearance_pending!
        receipt1 = create(:receipt, user: @user, project_unit: @project_unit, booking_detail: @booking_detail, total_amount: 40_000)
        receipt1.clearance_pending!
        receipt2 = create(:receipt, user: @user, project_unit: @project_unit, booking_detail: @booking_detail, total_amount: 40_000)
        patch :update,params: {id: @booking_detail_scheme.id, booking_detail_id: @booking_detail.id, booking_detail_scheme: {event: 'rejected'}}
      end
      it "booking_detail_scheme status changes to rejected" do
        expect(@booking_detail_scheme.reload.status).to eq('rejected')
      end
      it "booking_detail status changes to scheme_rejected" do 
        expect(@booking_detail.reload.status).to eq('scheme_rejected')
      end
      it "remove association of booking_detail and receipts " do
         
        receipts = @booking_detail.receipts
        receipts.each do |receipt|
          if receipt.status != 'pending'
            expect(receipt.reload.booking_detail_id).to eq(nil) 
          else
            expect(receipt.booking_detail_id).to eq(@booking_detail.id)
          end
        end
      end
    end
  end
end
