class ChannelPartnerObserverWorker
  include Sidekiq::Worker

  def perform(channel_partner_id, changes={})
    channel_partner = ChannelPartner.where(id: channel_partner_id).first
    if channel_partner.present?
      if (changed_keys = (changes.keys & %w(manager_id interested_services regions company_name)).presence) && changed_keys&.all? {|key| channel_partner[key].present?}
        channel_partner.users.each do |cp_user|
          Crm::Api::ExecuteWorker.perform_async('put', 'User', cp_user.id, nil, changes)
        end
      end

      # Push changes on User
      if (changed_keys = (changes.keys & %w(company_name company_type interested_services manager_id developers_worked_for pan_number rera_id gstin_number regions status)).presence) && changed_keys.all? {|key| channel_partner[key].present?}
        channel_partner.users.each do |cp_user|
          Crm::Api::ExecuteWorker.perform_async('post', 'User', cp_user.id, nil, changes)
        end
      end

      # Push events based on changed attributes
      if changes.has_key?('status') && channel_partner.status.present?
        channel_partner.users.each do |cp_user|
          Crm::Api::ExecuteWorker.perform_async('post', 'User', cp_user.id, 'Company Onboarding State Change', changes)
        end
      end
      if changes.has_key?('manager_id') && channel_partner.manager_id.present?
        channel_partner.users.each do |cp_user|
          Crm::Api::ExecuteWorker.perform_async('post', 'User', cp_user.id, 'Manager Changed', changes)
        end
      end
      if changes.has_key?('regions') && channel_partner.regions.present?
        regions_added = changes['regions'][1] - changes['regions'][0]
        regions_removed = changes['regions'][0] - changes['regions'][1]
        if regions_removed.present?
          regions_removed.each do |region|
            channel_partner.users.each do |cp_user|
              Crm::Api::ExecuteWorker.perform_async('post', 'User', cp_user.id, 'Region Removed', {'region_removed' => region})
            end
          end
        end
        if regions_added.present?
          regions_added.each do |region|
            channel_partner.users.each do |cp_user|
              Crm::Api::ExecuteWorker.perform_async('post', 'User', cp_user.id, 'Region Added', {'region_added' => region})
            end
          end
        end
      end
    end
  end
end
