module LeadStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event

    field :customer_status, type: String, default: 'registered'

    aasm :customer, column: :customer_status, whiny_transitions: false do
      state :registered, initial: true
      state :queued, :av_done, :engaged, :payment_done, :booking_done, :dropoff

      after_all_transitions :log_status_change

      event :queued, before: %w[unassign_queue_number], after: %w[assign_queue_number_or_revisit_queue_number] do
        transitions from: :registered, to: :queued
        transitions from: :dropoff, to: :queued
        transitions from: :payment_done, to: :queued
        transitions from: :booking_done, to: :queued
      end

      event :av_done do
        transitions from: :queued, to: :av_done
      end

      event :assign_sales, after: %w[check_payment], guard: :check_sales_availability do
        transitions from: :av_done, to: :engaged
        transitions from: :queued, to: :engaged
      end

      event :payment_done, after: %w[check_booking] do
        # add in after event of busy if customer has paymenr already
        transitions from: :engaged, to: :payment_done
      end

      event :booking_done, after: %w[free_manager] do
        transitions from: :payment_done, to: :booking_done
      end

      event :dropoff, after: %w[free_manager] do
        transitions from: :queued, to: :dropoff
        transitions from: :av_done, to: :dropoff
        transitions from: :engaged, to: :dropoff
        transitions from: :payment_done, to: :dropoff
      end
    end

    def log_status_change
      if self.state_transitions.present?
        _latest = self.state_transitions.desc(:created_at, sitevisit_id: self.current_site_visit_id).first
        if _latest.status == self.aasm(:customer).from_state.to_s
          _latest.update(exit_time: DateTime.now, sales_id: self.closing_manager_id)
        else
          _latest.error_list << "There is a log error."
        end
      end
      current_sitevisit = self.current_site_visit
      self.state_transitions << StateTransition.new(status: self.aasm(:customer).to_state, enter_time: DateTime.now, queue_number: current_sitevisit.queue_number, revisit_queue_number: current_sitevisit.revisit_queue_number, sitevisit_id: current_sitevisit.id, sales_id: self.closing_manager_id)
    end

    def unassign_queue_number
      self.update(queue_number: nil) unless self.queued?
      if self.closing_manager_id.present?
        self.update(closing_manager_id: nil)
      end
    end

    def assign_queue_number_or_revisit_queue_number
      current_sitevisit = self.current_site_visit
      if (!self.is_revisit?)
        current_sitevisit.assign!(:queue_number) && self.save
        st = self.state_transitions.where(status: 'queued', sitevisit_id: current_sitevisit.id).order(created_at: :desc).first
        st.set(queue_number: current_sitevisit.queue_number) if st.present?
        self.set(queue_number: current_sitevisit.queue_number) # this is for latest queue number
      else
        current_sitevisit.assign!(:revisit_queue_number) && self.save
        st = self.state_transitions.where(status: 'queued', sitevisit_id: current_sitevisit.id).order(created_at: :desc).first
        st.set(revisit_queue_number: current_sitevisit.revisit_queue_number) if st.present?
        self.set(queue_number: current_sitevisit.revisit_queue_number) # this is for latest queue number
      end
    end

    def check_sales_availability sales_id
      sales = User.where(id: sales_id.to_s).first
      return sales.present? && sales.available?
    end

    def check_payment
      if self.receipts.where(booking_detail_id: nil, status: {"$in": %w[success clearance_pending]}).present?
        self.payment_done!
      end
    end

    def assign_manager sales_id, old_sales_id = nil
      sales = User.where(id: sales_id.to_s).first
      if self.update(closing_manager_id: sales_id.to_s, accepted_by_sales: nil)
        if old_sales_id.present?
          old_sales = User.where(id: old_sales_id.to_s).first
          old_sales.available! if old_sales.may_available?
          self.current_site_visit&.set(sales_id: sales_id)
          reassign_log_status(old_sales_id)
        end
        return_val = sales.assign_customer!
        SelldoLeadUpdater.perform_async(self.id.to_s, {action: 'reassign_lead', sales_id: sales.selldo_uid}) if sales.selldo_uid.present?
        return_val
      end
    end
    
    def reassign_log_status(last_closing_manager_id = nil, event = "re-assigned")
      last_closing_manager_id = self.closing_manager_id if last_closing_manager_id.blank?
      current_sitevisit = self.current_site_visit
      _latest = self.state_transitions.desc(:created_at, sitevisit_id: self.current_site_visit_id).first
      _latest.update(exit_time: DateTime.now, sales_id: last_closing_manager_id, event: event)
      self.state_transitions << StateTransition.new(status: self.status, enter_time: DateTime.now, queue_number: current_sitevisit.queue_number, revisit_queue_number: current_sitevisit.revisit_queue_number, sitevisit_id: current_sitevisit.id, sales_id: self.closing_manager_id, event: event)
    end

    def check_booking
      if self.booking_details.where(status: {"$in": BookingDetail::BOOKING_STAGES }).present?
        self.booking_done!
      end
    end

    def free_manager
      sales = self.closing_manager
      if sales && sales.engaged?
        sales.available!
      end
    end

    def status
      customer_status
    end

    def move_to_next_state!(status)
      if self.respond_to?("may_#{status}?") && self.send("may_#{status}?")
        self.aasm(:customer).fire!(status.to_sym)
      else
        self.errors.add(:base, 'Invalid transition')
      end
      self.errors.empty?
    end
  end
end
