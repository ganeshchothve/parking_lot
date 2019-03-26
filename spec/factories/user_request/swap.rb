FactoryBot.define do
  factory :user_request_swap, class: UserRequest::Swap do
    status { 'pending' }
    association :booking_detail
    association :user
  end

  factory :pending_user_request_swap, parent: :user_request_swap do
    status { 'pending' }
  end

  factory :processing_user_request_swap, parent: :user_request_swap do
    status { 'processing' }
  end

  factory :resolved_user_request_swap, parent: :user_request_swap do
    status { 'resolved' }
  end

  factory :rejected_user_request_swap, parent: :user_request_swap do
    status { 'rejected' }
  end
end
