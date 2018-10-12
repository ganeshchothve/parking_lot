module SchemeStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event
     aasm column: :status do
      state :draft, initial: true
      state :approved, :disabled
       event :draft do
        transitions from: :draft, to: :draft
      end
       event :approved do
        transitions from: :approved, to: :approved
        transitions from: :draft, to: :approved, unless: :new_record?
      end
       event :disabled do
        transitions from: :disabled, to: :disabled
        transitions from: :draft, to: :disabled, unless: :new_record?
        transitions from: :approved, to: :disabled
      end
    end
     def self.minimal_discount_approver
      ["salesdiscountapprover@embassyindia.com"]
    end
     def self.larger_discount_approver
      ["managementdiscountapprover@embassyindia.com"]
    end
     def self.minimal_discount_value
      300
    end
     def approver? user
      if self.value.present?
        if self.value > self.class.minimal_discount_value
          self.class.larger_discount_approver.include?(user.email)
        else
          self.class.minimal_discount_approver.include?(user.email)
        end
      else
        self.class.larger_discount_approver.include?(user.email) || self.class.minimal_discount_approver.include?(user.email)
      end
    end
  end
end
