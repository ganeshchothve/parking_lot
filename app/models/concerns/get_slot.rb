module GetSlot
  extend ActiveSupport::Concern
  include ApplicationHelper
  included do
    before_update -> { finalise_time_slot }
  end

  def self.included(receiver)
    receiver.extend(ClassMethods)
    receiver.send(:include, InstanceMethods)
  end

  module InstanceMethods
    def calculate_time_slot
      slots_per_day = ((current_client.end_time - current_client.start_time) / 60).to_i / current_client.duration
      slot_number = (token_number - 1) / current_client.capacity
      date = current_client.slot_start_date + (slot_number / slots_per_day).days
      slot_start_time = current_client.start_time + ((slot_number % slots_per_day) * current_client.duration).minutes
      date = Time.zone.parse(date.strftime('%Y-%m-%d') + ' ' + slot_start_time.to_s(:time))
      slot = TimeSlot.new(date: date, start_time: date, end_time: date + current_client.duration.minutes)
    end

    def update_time_slot
      receipts = Receipt.where(token_number: token_number)
      if receipts.any? && receipts.first.try(:time_slot) # if token number and time slot are already assigned to another receipt
        errors.add(:token_number, 'Time Slot for this token number is not available.')
        false
        throw(:abort)
      else
        slot = calculate_time_slot
        if slot.date < Time.now # if time slot date is in the past
          errors.add(:token_number, 'Time Slot for this token number is in the past.')
          false
          throw(:abort)
        else
          self.time_slot = slot
        end
      end
    end

    def finalise_time_slot
      if time_slot.present?
        if token_number.blank?
          self.time_slot = nil
        elsif token_number_changed?
          update_time_slot
        end
      elsif status == 'success' && token_number.present?
        self.time_slot = calculate_time_slot
      end
    end
  end
end
