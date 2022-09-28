# UserRequests::BookingDetails::SwapProcess
module UserRequests
  module BookingDetails
    class SwapProcess
      include Sidekiq::Worker
      attr_accessor :user_request, :current_booking_detail, :alternate_project_unit, :current_project_unit

      def perform(user_request_id)
        @user_request = UserRequest.processing.where(_id: user_request_id).first
        return nil if @user_request.blank?
        @current_booking_detail = user_request.requestable
        if @current_booking_detail && @current_booking_detail.swapping?
          @alternate_project_unit = @user_request.alternate_project_unit
          if @alternate_project_unit.available?
            @current_project_unit = @current_booking_detail.project_unit
            resolve!
          else
            reject_user_request(I18n.t("worker.booking_details.errors.unit_swapping_unavailable"))
          end
        else
          reject_user_request(I18n.t("worker.booking_details.errors.booking_swapping_unavailable"))
        end
      end

      def update_receipts(error_messages, new_booking_detail)
        error_messages ||= []
        current_booking_detail.receipts.in(status: %w[pending clearance_pending success]).desc(:total_amount).each do |old_receipt|
          # TODO: :Error Handling for receipts remaining #SANKET
          new_receipt = old_receipt.dup
          new_receipt.booking_detail = new_booking_detail
          new_receipt.comments = I18n.t("worker.receipts.comments.swap_receipt_generated", name: old_receipt.id)
          old_receipt.comments ||= ''
          old_receipt.comments += I18n.t("worker.receipts.comments.swapped_receipt.cancellation", name: current_project_unit.id)
          old_receipt.set(token_number: nil) if old_receipt.token_number.present?          
          # Call callback after receipt is set to success so that booking detail status and project unit status get set accordingly
          if new_receipt.save
             # Copy token discount details over to new receipt & booking.
            if old_receipt.coupon.present? && new_receipt.token_eligible?
              new_receipt.generate_coupon
              new_booking_detail.update(token_discount: new_receipt.coupon.try(:value).to_f, variable_discount: new_receipt.coupon.try(:variable_discount).to_f)
            end
            
            if new_receipt.clearance_pending?
              new_receipt.clearance_pending!
            elsif new_receipt.success?
              new_receipt.after_success_event
            end

            unless old_receipt.cancel!
              error_messages.push(*old_receipt.errors.full_messages)
              break
            end

          else
            error_messages.push(*new_receipt.errors.full_messages)
            break
          end
        end
        error_messages
      end

      def build_booking_detail
        search = Search.find_or_create_by(lead_id: current_booking_detail.lead_id, user_id: current_booking_detail.user_id, project_unit_id: alternate_project_unit.id)

        BookingDetail.new(
          base_rate: alternate_project_unit.base_rate,
          project_name: alternate_project_unit.project_name,
          project_tower_name: alternate_project_unit.project_tower_name,
          bedrooms: alternate_project_unit.bedrooms,
          bathrooms: alternate_project_unit.bathrooms,
          floor_rise: alternate_project_unit.floor_rise,
          saleable: alternate_project_unit.saleable,
          project_unit_id: alternate_project_unit.id,
          project_id: alternate_project_unit.project_id,
          costs: alternate_project_unit.costs, data: alternate_project_unit.data,
          primary_user_kyc_id: current_booking_detail.primary_user_kyc_id,
          status: 'hold', user_id: current_booking_detail.user_id,
          manager: current_booking_detail.try(:manager_id),
          user_kyc_ids: current_booking_detail.user_kyc_ids,
          parent_booking_detail_id: current_booking_detail.id,
          booking_portal_client_id: alternate_project_unit.booking_portal_client_id,
          search: search,
          lead: search.lead,
          user: search.lead.user,
          creator_id: current_booking_detail.try(:creator).try(:id)
        )
      end

      def build_booking_detail_scheme(new_booking_detail)
        new_booking_detail_scheme = current_booking_detail.booking_detail_scheme.dup
        new_booking_detail_scheme.project_unit = alternate_project_unit
        new_booking_detail_scheme.project_id = alternate_project_unit.project_id
        new_booking_detail_scheme.booking_detail = new_booking_detail
        # Assign derived_from_scheme to tower default scheme in case of new tower selected in swap.
        unless current_project_unit.project_tower.id == alternate_project_unit.project_tower.id
          new_booking_detail_scheme.derived_from_scheme = new_booking_detail.project_unit.project_tower.default_scheme
          new_booking_detail_scheme.payment_schedule_template_id = new_booking_detail_scheme.derived_from_scheme.payment_schedule_template_id
          new_booking_detail_scheme.cost_sheet_template_id = new_booking_detail_scheme.derived_from_scheme.cost_sheet_template_id
        end
        new_booking_detail_scheme
      end

      # When processing fails the old project unit is restored to its previous state, booking detail is marked as swap rejected and then appropriate state, user request is rejected
      def reject_user_request(error_messages, alternate_project_unit_status=nil, new_booking_detail=nil)

        if alternate_project_unit.present?
          new_booking_detail ||= current_booking_detail.related_booking_details.where(project_unit_id: alternate_project_unit.id).first
          alternate_project_unit.make_available
          alternate_project_unit.save
        end

        new_booking_detail.destroy if new_booking_detail

        user_request.reason_for_failure = error_messages.join(', ') if error_messages.is_a?(Array)

        unless user_request.rejected!
          # As request in invalid so its force fully rejected.
          user_request.reason_for_failure += ( ' ' + user_request.errors.full_messages.join(' ') )
          user_request.status = 'rejected'
          user_request.save(validate: false)
        end

        current_booking_detail.try(:swap_rejected!)
      end

      # This method tries to resolve a user_request and marks it as resolved if the processing is successful otherwise rejects the request. New booking detail object is created with new booking detail scheme. All the old receipts are marked as cancelled and new receipts are attached to the new booking detail object. Then the old project unit is made available and new project unit and booking detail are blocked. Also old booking detail object is marked swapped
      def resolve!
        error_messages = []
        alternate_project_unit_status = alternate_project_unit.status
        new_booking_detail = build_booking_detail
        if current_booking_detail.receipts.in(status: %w[clearance_pending success]).where(total_amount: { '$gte' => alternate_project_unit.blocking_amount }).present?
          if new_booking_detail.save
            new_booking_detail_scheme = build_booking_detail_scheme(new_booking_detail)
            if new_booking_detail_scheme.save

              update_receipts(error_messages, new_booking_detail)
              if error_messages.blank?
                current_booking_detail.swapped!
              else
                # Reject swap request because updation of receipts failed
                reject_user_request(error_messages, alternate_project_unit_status, new_booking_detail)
              end
            else
              # Reject Swap Request because saving new_booking_detail_scheme failed
              # Delete new_booking_detail
              error_messages.push(*new_booking_detail_scheme.errors.full_messages)
              reject_user_request(error_messages, alternate_project_unit_status, new_booking_detail)
            end
          else
            error_messages.push(*new_booking_detail.errors.full_messages)
            # Reject swap Request because saving new_booking_detail failed
            reject_user_request(error_messages, alternate_project_unit_status, new_booking_detail)
          end
        else
          # Reject swap Request because alternative blocking_amount is very high
          reject_user_request(I18n.t("worker.booking_details.errors.reject_user_request", name: alternate_project_unit.blocking_amount), alternate_project_unit_status, new_booking_detail)
        end
      end
    end
  end
end
