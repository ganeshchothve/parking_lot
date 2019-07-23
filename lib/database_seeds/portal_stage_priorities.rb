# DatabaseSeeds::PortalStagePriorities.seed()
module DatabaseSeeds
  module PortalStagePriorities
    def self.seed client_id=nil
      i = 1
      ['registered', 'confirmed', 'project_info', 'kyc_done', 'unit_browsing', 'unit_selected', 'hold_payment_dropoff', 'payment_done', 'blocked', 'booked_tenative', 'booked_confirmed', 'cancelled'].each do |stage|
        psp = PortalStagePriority.find_or_create_by(stage: stage)
        psp.priority = i
        if psp.save
          i += 1
        end
      end
    end
  end
end
