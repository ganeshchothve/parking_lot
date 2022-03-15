module SalesUserStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event

    field :sales_status, type: String, default: 'available'

    aasm :sales, column: :sales_status, whiny_transitions: false do
      state :available, initial: true
      state :engaged, :not_available, :break

      event :assign_customer do
        transitions from: :available, to: :engaged
      end

      event :not_available do
        transitions from: :available, to: :not_available
      end

      event :break do
        transitions from: :available, to: :break
      end

      event :available do
        transitions from: :engaged, to: :available, guard: :check_customer_status
        transitions from: :not_available, to: :available
        transitions from: :break, to: :available
      end
    end

    def check_customer_status
      Lead.where(closing_manager_id: self.id).in(customer_status: %w(engaged payment_done)).blank?
    end

    def move_to_next_state!(status)
      if role?('sales')
        if self.respond_to?("may_#{status}?") && self.send("may_#{status}?")
          self.aasm(:sales).fire!(status.to_sym)
        else
          self.errors.add(:base, 'Invalid transition')
        end
      else
        self.errors.add(:base, 'Operation not supported')
      end
      self.errors.empty?
    end
  end
end
