require 'rails_helper'

RSpec.describe SearchesController, type: :controller do
  before do
    create(:admin)
  end

  describe 'HOLD' do
    it 'throws error when user has not completed his or her kyc' do
      project_unit.client_id = Client.first
      project_unit.user = user
      post :hold, params: { id: search.id, project_unit: project_unit.as_json }
      expect(response.request.flash[:alert]).to eq('The user is not confirmed or kyc documents are not uploaded.')
    end
    it 'throws error when the unit is already held' do
      client.allow_multiple_bookings_per_user_kyc = false
      client.save
      user.booking_portal_client = client
      user.user_kycs << create(:user_kyc, creator_id: user.id, user: user)
      user.save
      project_unit.client_id = client.id
      project_unit.user = user
      project_unit.primary_user_kyc_id = user.user_kycs.first.id
      project_unit.status = 'hold'
      project_unit.save
      another_user = create(:user, booking_portal_client: client)
      another_user.user_kycs << create(:user_kyc, creator_id: another_user.id, user: another_user)
      search.user = another_user
      post :hold, params: { id: search.id, project_unit: project_unit.as_json }
      expect(response.request.flash[:alert]).to eq('This unit is already held by other user.')
    end
    it 'throws error when user has reached max allowed bookings' do
      user.set(allowed_bookings: 0)
      project_unit.client_id = Client.first
      user.booking_portal_client ||= (Client.asc(:created_at).first || create(:client))
      user.user_kycs << create(:user_kyc, creator_id: user.id, user: user)
      project_unit.user = user
      post :hold, params: { id: search.id, project_unit: project_unit.as_json }
      expect(response.request.flash[:alert]).to eq('You have booked the permitted number of apartments.')
    end
    it 'throws error when user does not have unused kyc id ' do
      client.allow_multiple_bookings_per_user_kyc = false
      client.save
      user.booking_portal_client = client
      user.user_kycs << create(:user_kyc, creator_id: user.id, user: user, phone: '9753736524')
      user.save
      project_unit.client_id = client.id
      project_unit.user = user
      project_unit.primary_user_kyc_id = user.user_kycs.first.id
      project_unit.status = 'blocked'
      project_unit.save
      another_project_unit = create(:project_unit, project: project, booking_portal_client: client, project_tower: project_tower)
      another_project_unit.user = user
      search.project_unit_id = another_project_unit.id
      search.save
      post :hold, params: { id: search.id, project_unit: another_project_unit.as_json }
      expect(response.request.flash[:alert]).to eq('You can book only one unit on one KYC.')
    end
    %w[cp sales sales_admin cp_admin admin superadmin channel_partner].each do |user_role|
      describe "Admin Side" do
        before(:each) do
          client = Client.last || create(:client)
          client.set(enable_actual_inventory: [user_role], enable_channel_partners: true)

          @admin = create(user_role)
          sign_in_app(@admin)
        end

        describe "for #{user_role}" do

          before(:each) do
            @user = create(:user)
            if @admin.role?('channel_partner')
              @user.set(manager_id: @admin.id)
              # Need to valid need_unattached_booking_receipts_for_channel_partner for channel_partner
              allow_any_instance_of(User).to receive(:unattached_blocking_receipt).and_return(Receipt.new)
            end
            @kyc = create(:user_kyc, user: @user, creator: @user)
            @project_unit = create(:available_project_unit)
            @project_unit.project_tower.default_scheme.set(can_be_applied_by: ['channel_partner'])
            @search = create(:search, project_unit_id: @project_unit.id, user: @user)
          end

          # enable_actual_inventory?
          context 'When Inventory is not added for client' do
            it 'throws error to add inventory and contact administrator' do
              allow_any_instance_of(Client).to receive(:enable_actual_inventory).and_return([])
              post :hold, params: { id: @search.id, booking_detail: { primary_user_kyc_id: @user.id } }
              expect(response.request.flash[:alert]).to eq('You can not select Inventory. Please contact to Administrator.')
            end
          end

          # only_for_confirmed_user!
          context 'When buyer is not yet confirmed.' do
            it 'throws error to confirm user' do
              allow_any_instance_of(User).to receive(:confirmed_at).and_return(nil)
              post :hold, params: { id: @search.id, booking_detail: { primary_user_kyc_id: @user.id } }
              expect(response.request.flash[:alert]).to eq('You have to confirm your email address before continuing.')
            end
          end

          # only_for_kyc_added_users!
          context 'When KYC is missing on buyer' do
            it 'throws error to add kyc' do
              allow_any_instance_of(User).to receive(:user_kyc_ids).and_return([])
              post :hold, params: { id: @search.id, booking_detail: { primary_user_kyc_id: @user.id } }
              expect(response.request.flash[:alert]).to eq('Please add KYC before booking Unit.')
            end
          end

          # only_single_unit_can_hold!
          context 'When already hold one project unit' do
            it 'throws an error as one unit is already held.' do
              project_unit = create(:available_project_unit)
              booking_detail = create(:booking_detail, project_unit_id: project_unit.id, user_id: @user.id, status: 'hold', primary_user_kyc_id: @kyc.id)
              post :hold, params: { id: @search.id, booking_detail: { primary_user_kyc_id: @user.id } }
              expect(response.request.flash[:alert]).to eq('User already has a unit on hold.')
            end
          end

          # available_for_user_group?
          context 'When buyer(user) try to book management unit' do
            it 'throws an error to you are not authorise' do
              allow_any_instance_of(ProjectUnit).to receive(:status).and_return('management')
              post :hold, params: { id: @search.id, booking_detail: { primary_user_kyc_id: @user.id } }
              expect(response.request.flash[:alert]).to eq('This unit is not for current user group.')
            end
          end

          # is_buyer_booking_limit_exceed?
          context 'When buyer(user) cross booking limit' do
            it 'throws an error that ' do
              allow_any_instance_of(User).to receive(:allowed_bookings).and_return(0)
              post :hold, params: { id: @search.id, booking_detail: { primary_user_kyc_id: @kyc.id } }
              expect(response.request.flash[:alert]).to eq('You have booked the permitted number of apartments.')
            end
          end

          # buyer_kyc_booking_limit_exceed?
          context 'When buyer(user) KYC booking excced' do
            it 'throws error to add kyc' do
              allow_any_instance_of(User).to receive(:allowed_bookings).and_return(2)
              allow_any_instance_of(Client).to receive(:allow_multiple_bookings_per_user_kyc?).and_return(false)
              project_unit = create(:available_project_unit)
              booking_detail = create(:booking_detail, project_unit_id: project_unit.id, user_id: @user.id, status: 'blocked', primary_user_kyc_id: @kyc.id)
              post :hold, params: { id: @search.id, booking_detail: { primary_user_kyc_id: @kyc.id } }
              expect(response.request.flash[:alert]).to eq('Multiple KYC booking is not allowed.')
            end
          end

          # success
          context 'when success request' do
            it 'return suucess message and redirect to payment page' do
              post :hold, params: { id: @search.id, booking_detail: { primary_user_kyc_id: @kyc.id } }
              expect(response.request.flash[:notice]).to eq('Your Booking is hold. Please select Scheme and go for Payment.')
            end
          end
        end
      end
    end

    describe 'for channel_partner' do
      before(:each) do
        client = Client.last || create(:client)
        client.set(enable_actual_inventory: ['channel_partner'], enable_channel_partners: true)

        @admin = create(:channel_partner)
        @user = create(:user, manager_id: @admin.id)
        @kyc = create(:user_kyc, user: @user, creator: @user)
        @project_unit = create(:available_project_unit)
        @search = create(:search, project_unit_id: @project_unit.id, user: @user)
        sign_in_app(@admin)
      end

      # _role_based_check
      context ' when channel_partner try to book unit for another buyer which is not added by him' do
        it 'then throws an error as "your not authorise to book"' do
          allow_any_instance_of(User).to receive(:manager_id).and_return(nil)
          post :hold, params: { id: @search.id, booking_detail: { primary_user_kyc_id: @user.id } }
          expect(response.request.flash[:alert]).to eq('You do not have access to book for this buyer.')
        end
      end

      # need_unattached_booking_receipts_for_channel_partner
      context ' when channel_partner try to book unit for buyer but there is no any unattached payment.' do
        it 'then throws an error as "booking amount is missing"' do
          post :hold, params: { id: @search.id, booking_detail: { primary_user_kyc_id: @user.id } }
          expect(response.request.flash[:alert]).to eq('For Channal Partner. Need atleast one unattach booking amount receipt.')
        end
      end
    end

    %w[user employee_user management_user].each do |buyer_role|
      describe "Buyer Side" do
        before(:each) do
          client = Client.last || create(:client)
          client.set(enable_actual_inventory: [buyer_role], enable_company_users: true)

          @user = create(buyer_role)
          sign_in_app(@user)
        end

        describe "for #{buyer_role}" do

          before(:each) do
            @kyc = create(:user_kyc, user: @user, creator: @user)
            @project_unit = create(:available_project_unit)
            @search = create(:search, project_unit_id: @project_unit.id, user: @user)
          end

          # enable_actual_inventory?
          context "When Inventory is not added for #{buyer_role}" do
            it 'throws error to add inventory and contact administrator' do
              allow_any_instance_of(Client).to receive(:enable_actual_inventory).and_return([])
              post :hold, params: { id: @search.id, booking_detail: { primary_user_kyc_id: @user.id } }
              expect(response.request.flash[:alert]).to eq('You can not select Inventory. Please contact to Administrator.')
            end
          end

          # only_for_confirmed_user!
          context 'When buyer is not yet confirmed.' do
            it 'throws error to confirm user' do
              allow_any_instance_of(User).to receive(:confirmed_at).and_return(nil)
              post :hold, params: { id: @search.id, booking_detail: { primary_user_kyc_id: @user.id } }
              expect(response.request.flash[:alert]).to eq('You have to confirm your email address before continuing.')
            end
          end

          # only_for_kyc_added_users!
          context 'When KYC is missing on buyer' do
            it 'throws error to add kyc' do
              allow_any_instance_of(User).to receive(:user_kyc_ids).and_return([])
              post :hold, params: { id: @search.id, booking_detail: { primary_user_kyc_id: @user.id } }
              expect(response.request.flash[:alert]).to eq('Please add KYC before booking Unit.')
            end
          end

          # only_single_unit_can_hold!
          context 'When already hold one project unit' do
            it 'throws an error as one unit is already held.' do
              project_unit = create(:available_project_unit)
              booking_detail = create(:booking_detail, project_unit_id: project_unit.id, user_id: @user.id, status: 'hold', primary_user_kyc_id: @kyc.id)
              post :hold, params: { id: @search.id, booking_detail: { primary_user_kyc_id: @user.id } }
              expect(response.request.flash[:alert]).to eq('User already has a unit on hold.')
            end
          end

          # available_for_user_group?
          context 'When buyer(user) try to book management unit' do
            it 'throws an error to you are not authorise' do
              allow_any_instance_of(ProjectUnit).to receive(:status).and_return('management')
              post :hold, params: { id: @search.id, booking_detail: { primary_user_kyc_id: @user.id } }
              expect(response.request.flash[:alert]).to eq('This unit is not for current user group.')
            end
          end

          # is_buyer_booking_limit_exceed?
          context 'When buyer(user) cross booking limit' do
            it 'throws an error that ' do
              allow_any_instance_of(User).to receive(:allowed_bookings).and_return(0)
              post :hold, params: { id: @search.id, booking_detail: { primary_user_kyc_id: @kyc.id } }
              expect(response.request.flash[:alert]).to eq('You have booked the permitted number of apartments.')
            end
          end

          # buyer_kyc_booking_limit_exceed?
          context 'When buyer(user) KYC booking excced' do
            it 'throws error to add kyc' do
              allow_any_instance_of(User).to receive(:allowed_bookings).and_return(2)
              allow_any_instance_of(Client).to receive(:allow_multiple_bookings_per_user_kyc?).and_return(false)
              project_unit = create(:available_project_unit)
              booking_detail = create(:booking_detail, project_unit_id: project_unit.id, user_id: @user.id, status: 'blocked', primary_user_kyc_id: @kyc.id)
              post :hold, params: { id: @search.id, booking_detail: { primary_user_kyc_id: @kyc.id } }
              expect(response.request.flash[:alert]).to eq('Multiple KYC booking is not allowed.')
            end
          end

          # success
          context 'when success request' do
            it 'return suucess message and redirect to payment page' do
              expect{ post :hold, params: { id: @search.id, booking_detail: { primary_user_kyc_id: @kyc.id } } }.to change(BookingDetail, :count).by(1)
              expect(response.request.flash[:notice]).to eq('Your Booking is hold. Please select Scheme and go for Payment.')
            end

          end
        end
      end
    end
  end

  describe 'CHECKOUT' do
  end
end
