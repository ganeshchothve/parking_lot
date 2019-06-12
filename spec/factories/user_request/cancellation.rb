FactoryBot.define do
  factory :user_request_cancellation, class: UserRequest::Cancellation do
    status { 'pending' }
    # association :booking_detail
    association :user
  end

  factory :pending_user_request_cancellation, parent: :user_request_cancellation do
    status { 'pending' }
  end

  factory :processing_user_request_cancellation, parent: :user_request_cancellation do
    status { 'processing' }
  end

  factory :resolved_user_request_cancellation, parent: :user_request_cancellation do
    status { 'resolved' }
  end

  factory :rejected_user_request_cancellation, parent: :user_request_cancellation do
    status { 'rejected' }
  end
end
