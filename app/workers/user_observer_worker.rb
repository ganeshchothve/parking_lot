class UserObserverWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'event'

  def perform(user_id, action='create', changes={})
    user = User.where(id: user_id).first
    if user.present?
      if action == 'create'

        if user.role.in?(%w(cp_owner channel_partner))
          Crm::Api::ExecuteWorker.perform_async('post', 'User', user.id)
          Crm::Api::ExecuteWorker.perform_async('put', 'User', user.id)
        else
          crm_base = Crm::Base.where(domain: ENV_CONFIG.dig(:interakt, :base_url)).first
          Crm::Api::ExecuteWorker.perform_async('post', 'User', user.id, nil, {}, crm_base&.id)
        end

      elsif action == 'update'

        if user.role.in?(%w(cp_owner channel_partner))

          # For calling Selldo APIs
          if (changed_keys = (changes.keys & %w(role channel_partner_id)).presence) && changed_keys&.all? {|key| user[key].present?}
            Crm::Api::ExecuteWorker.perform_async('put', 'User', user.id, nil, changes)
          end

          # For calling Interakt APIs
          if (changed_keys = (changes.keys & %w(first_name last_name email phone role channel_partner_id manager_id is_active sign_in_count current_sign_in_at)).presence) && changed_keys.reject {|key| user[key]&.is_a?(Boolean)}&.all? {|key| user[key].present?}
            if changed_keys.include?('channel_partner_id') && (channel_partner_id = changes.dig('channel_partner_id', 1).presence)
              channel_partner = ChannelPartner.where(id: channel_partner_id).first
            else
              channel_partner = user.channel_partner
            end
            payload = {
              'channel_partner' => channel_partner&.as_json(include: {primary_user: {methods: [:name]}})
            }.merge(changes || {})

            Crm::Api::ExecuteWorker.perform_async('post', 'User', user.id, nil, payload)
          end
          # Update primary user details on all company users in case of changes
          if user.role?('cp_owner') && user.channel_partner&.primary_user_id == user.id && (changed_keys = (changes.keys & %w(first_name last_name phone)).presence) && changed_keys&.all? {|key| user[key].present?}
            changed_payload = changed_keys.inject({}) do |hsh, key|
              hsh[key] = changes.dig(key, 1)
              hsh
            end
            user.channel_partner.users.ne(id: user.id).each do |cp_user|
              Crm::Api::ExecuteWorker.perform_async('post', 'User', cp_user.id, nil, { 'primary_owner' => changed_payload })
            end
          end
          # Send manager change on channel_partner/cp_owner user
          if changes.has_key?('manager_id') && changes.dig('manager_id', 1).present?
            Crm::Api::ExecuteWorker.perform_async('post', 'User', user.id, 'Manager Changed', changes)
          end
          # Send company change on channel_partner/cp_owner user
          if changes.has_key?('channel_partner_id') && (channel_partner_id = changes.dig('channel_partner_id', 1).presence)
            payload = {
              'channel_partner' => ChannelPartner.where(id: channel_partner_id).first&.as_json(include: {primary_user: {methods: [:name]}, manager: {methods: [:name]}})
            }.merge(changes || {})
            Crm::Api::ExecuteWorker.perform_async('post', 'User', user.id, 'Company Changed', payload)
          end
          # Send account activeness change on channel_partner/cp_owner user
          if changes.has_key?('is_active')
            if changes.dig('is_active', 1).present?
              Crm::Api::ExecuteWorker.perform_async('post', 'User', user.id, 'Account Active', changes)
            elsif changes.dig('is_active', 1).blank?
              Crm::Api::ExecuteWorker.perform_async('post', 'User', user.id, 'Account Inactive', changes)
            end
          end
          # Send manager change on channel_partner/cp_owner user
          if changes.has_key?('sign_in_count') && changes.dig('sign_in_count', 1) == 1
            Crm::Api::ExecuteWorker.perform_async('post', 'User', user.id, 'First Sign In', changes)
          end

        else

          # For calling Interakt APIs
          if (changed_keys = (changes.keys & %w(first_name last_name email phone project_ids)).presence) && changed_keys&.all? {|key| user[key].present?}
            Crm::Api::ExecuteWorker.perform_async('post', 'User', user.id, nil, changes)
          end

        end

      end

    end
  end
end
