module GetSlot
  extend ActiveSupport::Concern
  include ApplicationHelper
  included do
    after_save -> { calculate_slot }
  end

  def self.included(receiver)
    receiver.extend(ClassMethods)
    receiver.send(:include, InstanceMethods)
  end

  module InstanceMethods
    def calculate_slot
      if time_slot.present? ? token_number_changed? : status == 'success'
        slots_per_day = ((current_client.end_time - current_client.start_time) / 60).to_i / current_client.duration
        slot_number = (token_number - 1) / current_client.capacity
        date = current_client.slot_start_date + (slot_number / slots_per_day).days
        slot_start_time = current_client.start_time + ((slot_number % slots_per_day) * current_client.duration).minutes
        self.time_slot = TimeSlot.new(date: date, start_time: slot_start_time, end_time: slot_start_time + current_client.duration.minutes)
      end
    end
  end
end
