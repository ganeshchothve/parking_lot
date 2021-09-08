module QueueNumberAssignment
  extend ActiveSupport::Concern
  include ApplicationHelper
  included do
    field :queue_number, type: Integer
    field :revisit_queue_number, type: Integer

    increments :queue_number, seed: 0, auto: false
    increments :revisit_queue_number, seed: 10000, auto: false

    # Validations
    validates :queue_number, uniqueness: true, allow_nil: true
    validates :revisit_queue_number, uniqueness: true, allow_nil: true

    # Callbacks
    # before_save :assign_queue_number
  end

  # def assign_queue_number
  #   assign!(:queue_number) && save
  #   st = self.state_transitions.where(status: 'queued').order(created_at: :desc).first
  #   st.set(queue_number: self.queue_number) if st.present?
  # end

end
