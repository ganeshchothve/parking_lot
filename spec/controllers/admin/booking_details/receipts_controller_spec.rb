require 'rails_helper'
RSpec.describe Admin::BookingDetails::ReceiptsController, type: :controller do
  describe 'creating receipt' do # ToDo Remove extra code repeated code
    it 'selects account linked to the phase if phase and account both are present' do
      phase = create(:phase)
      default = create(:razorpay_payment, by_default: true)
      not_default = create(:razorpay_payment, by_default: false)
      not_default.phases << phase
      client = create(:client)
      admin = create(:admin)
      sign_in_app(admin)
      @user = create(:user)
      kyc = create(:user_kyc, creator_id: @user.id, user: @user)
      @project_unit = create(:project_unit)
      @project_unit.status = 'hold'
      @project_unit.user = @user
      @project_unit.primary_user_kyc_id = kyc.id
      @project_unit.save
      search = Search.create(created_at: Time.now, updated_at: Time.now, bedrooms: 2.0, carpet: nil, agreement_price: nil, all_inclusive_price: nil, project_tower_id: nil, floor: nil, project_unit_id: nil, step: 'filter', results_count: nil, user_id: @user.id)
      pubs = ProjectUnitBookingService.new(@project_unit)
      pubs.create_booking_detail(search.id)
      receipt_params = FactoryBot.attributes_for(:receipt)
      post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @project_unit.booking_detail.id }
      post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @project_unit.booking_detail.id }
      receipt = Receipt.first
      receipt.success!
      receipt1 = Receipt.first
      receipt1.success!
      expect(receipt1.account.by_default).to eq(false)
    end
    it 'selects default account when phase is missing or account is missing' do
      phase = create(:phase)
      default = create(:razorpay_payment, by_default: true)
      not_default = create(:razorpay_payment, by_default: false)
      client = create(:client)
      admin = create(:admin)
      sign_in_app(admin)
      @user = create(:user)
      kyc = create(:user_kyc, creator_id: @user.id, user: @user)
      @project_unit = create(:project_unit)
      @project_unit.status = 'hold'
      @project_unit.user = @user
      @project_unit.primary_user_kyc_id = kyc.id
      @project_unit.save
      search = Search.create(created_at: Time.now, updated_at: Time.now, bedrooms: 2.0, carpet: nil, agreement_price: nil, all_inclusive_price: nil, project_tower_id: nil, floor: nil, project_unit_id: nil, step: 'filter', results_count: nil, user_id: @user.id)
      pubs = ProjectUnitBookingService.new(@project_unit)
      pubs.create_booking_detail(search.id)
      receipt_params = FactoryBot.attributes_for(:receipt)
      post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @project_unit.booking_detail.id }
      receipt = Receipt.first
      receipt.success!
      expect(receipt.account.by_default).to eq(true)
    end
  end

  describe 'payment mode ONLINE' do
    before(:each) do
      default = create(:razorpay_payment, by_default: true)
      @client = create(:client)
      @admin = create(:admin)
      @user = create(:user)
      sign_in_app(@admin)
      kyc = create(:user_kyc, creator_id: @user.id, user: @user)
      @project_unit = create(:project_unit, status: 'hold', user: @user, primary_user_kyc_id: kyc.id)
      # @booking_detail = create(:booking_detail, project_unit: @project_unit, user: @user, primary_user_kyc_id: kyc.id, search_id: @search.id)
      @search = Search.create(created_at: Time.now, updated_at: Time.now, bedrooms: 2.0, carpet: nil, agreement_price: nil, all_inclusive_price: nil, project_tower_id: nil, floor: nil, project_unit_id: nil, step: 'filter', results_count: nil, user_id: @user.id)
      @pubs = ProjectUnitBookingService.new(@project_unit)
      @booking_detail = @pubs.create_booking_detail @search.id
    end

    it 'receipt saved successful' do
      receipt_params = FactoryBot.attributes_for('receipt')
      post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @booking_detail.id }
      receipt = Receipt.first
      expect(response.request.flash[:notice]).to eq('Receipt was successfully updated. Please upload documents')
      search_id = receipt.user.searches.desc(:created_at).first.id
      expect(response).to redirect_to("/dashboard/user/searches/#{search_id}/gateway-payment/#{receipt.receipt_id}")
    end

    it 'if receipt account blank, render error message in flash' do
      Receipt.any_instance.stub(:account).and_return nil
      receipt_params = FactoryBot.attributes_for(:receipt)
      post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @booking_detail.id }
      expect(response.request.flash[:alert]).to eq('We do not have any Account Details for Transaction. Please ask Administrator to add.')
      expect(response).to render_template('new')
    end

    it 'receipt save fails' do
      Receipt.any_instance.stub(:save).and_return false
      Receipt.any_instance.stub(:errors).and_return(ActiveModel::Errors.new(Receipt.new).tap { |e| e.add(:payment_identifier, 'cannot be blank') })
      receipt_params = FactoryBot.attributes_for(:receipt)
      post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @booking_detail.id }
      expect(response).to render_template('new')
    end
  end

  describe 'payment mode' do
    before(:each) do
      create(:razorpay_payment, by_default: true)
    end

    context do
      %w[cheque rtgs neft imps card_swipe].each do |payment_mode|
        before(:each) do
          @client = create(:client)
          @admin = create(:admin)
          @user = create(:user)
          sign_in_app(@admin)
          kyc = create(:user_kyc, creator_id: @user.id, user: @user)
          @project_unit = create(:project_unit, status: 'hold', user: @user, primary_user_kyc_id: kyc.id)
          # @booking_detail = create(:booking_detail, project_unit: @project_unit, user: @user, primary_user_kyc_id: kyc.id, search_id: @search.id)
          @search = Search.create(created_at: Time.now, updated_at: Time.now, bedrooms: 2.0, carpet: nil, agreement_price: nil, all_inclusive_price: nil, project_tower_id: nil, floor: nil, project_unit_id: nil, step: 'filter', results_count: nil, user_id: @user.id)
          @pubs = ProjectUnitBookingService.new(@project_unit)
          @booking_detail = @pubs.create_booking_detail @search.id
        end

        it "#{payment_mode} receipt saved successful" do
          receipt_params = FactoryBot.attributes_for(:offline_payment, payment_mode: payment_mode.to_s)
          post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @booking_detail.id }
          receipt = Receipt.first
          expect(response.request.flash[:notice]).to eq('Receipt was successfully updated. Please upload documents')
          search_id = receipt.user.searches.desc(:created_at).first.id
          expect(response).to redirect_to("#{admin_user_receipts_path(@user)}?remote-state=#{assetables_path(assetable_type: receipt.class.model_name.i18n_key.to_s, assetable_id: receipt.id)}")
        end

        it "if #{payment_mode} receipt account blank, render error message in flash" do
          Receipt.any_instance.stub(:account).and_return nil
          receipt_params = FactoryBot.attributes_for(:offline_payment, payment_mode: payment_mode.to_s)
          post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @booking_detail.id }
          expect(response.request.flash[:alert]).to eq('We do not have any Account Details for Transaction. Please ask Administrator to add.')
          expect(response).to render_template('new')
        end

        it "#{payment_mode} receipt save fails" do
          Receipt.any_instance.stub(:save).and_return false
          Receipt.any_instance.stub(:errors).and_return(ActiveModel::Errors.new(Receipt.new).tap { |e| e.add(:payment_identifier, 'cannot be blank') })
          receipt_params = FactoryBot.attributes_for(:offline_payment, payment_mode: payment_mode.to_s)
          post :create, params: { receipt: receipt_params, user_id: @user.id, booking_detail_id: @booking_detail.id }
          expect(response).to render_template('new')
        end
      end
    end
  end
end
