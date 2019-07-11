# DatabaseSeeds::PortalStagePriorities.seed()
module DatabaseSeeds
  module PortalStagePriorities
    def self.seed client_id=nil
      i = 1
      ['registered', 'project_info', 'confirmed', 'booking_blocked', 'booked_tentative', 'blocked', 'cancelled', 'hold_payment_dropoff', 'unit_browsing', 'unit_selected'].each do |stage|
        psp = PortalStagePriority.find_or_create_by(stage: stage)
        psp.priority = i
        if psp.save
          i += 1
        end
      end
    end
  end
end