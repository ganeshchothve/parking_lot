module CampaignStateMachine
  extend ActiveSupport::Concern
  included do
    include AASM
    attr_accessor :event
    
  end
end
