class UserObserverWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'event'

  def perform(user_id, action='create', changes={})
    user = User.where(id: user_id).first
    booking_portal_client_id = user.try(:booking_portal_client_id)
    if user.present?
      interakt_base = Crm::Base.where(domain: ENV_CONFIG.dig(:interakt, :base_url), booking_portal_client_id: booking_portal_client_id).first
      selldo_base = Crm::Base.where(domain: ENV_CONFIG.dig(:selldo, :base_url), booking_portal_client_id: booking_portal_client_id).first
      razorpay_base = Crm::Base.where(domain: ENV_CONFIG.dig(:razorpay, :base_url), booking_portal_client_id: booking_portal_client_id).first
      onesignal_base = Crm::Base.where(domain: ENV_CONFIG.dig(:onesignal, :base_url), booking_portal_client_id: booking_portal_client_id).first

      if action == 'create'

        if user.role.in?(%w(cp_owner channel_partner))
          # push cp_owners / channel partners to all the platforms configured in api
          Crm::Api::ExecuteWorker.new.perform('post', 'User', user.id)
          Crm::Api::ExecuteWorker.perform_async('put', 'User', user.id, nil, {}, selldo_base.id.to_s) if selldo_base
        else
          Crm::Api::ExecuteWorker.new.perform('post', 'User', user.id, nil, {}, interakt_base.id) if interakt_base
        end

      elsif action == 'update'

        if user.role.in?(%w(cp_owner channel_partner))

          # For calling Selldo APIs
          if selldo_base
            if (changed_keys = (changes.keys & %w(role channel_partner_id confirmed_at manager_id)).presence) && changed_keys&.all? {|key| user[key].present?}
              Crm::Api::ExecuteWorker.perform_async('put', 'User', user.id, nil, changes, selldo_base.id.to_s)
            end
          end

          if (changed_keys = (changes.keys & %w(first_name last_name email phone role channel_partner_id manager_id is_active sign_in_count current_sign_in_at user_status_in_company)).presence) && changed_keys.reject {|key| user[key]&.is_a?(Boolean)}&.all? {|key| user[key].present?}
            if changed_keys.include?('channel_partner_id') && (channel_partner_id = changes.dig('channel_partner_id', 1).presence)
              channel_partner = ChannelPartner.where(id: channel_partner_id).first
            else
              channel_partner = user.channel_partner
            end
            payload = {
              'channel_partner' => channel_partner&.as_json(include: {primary_user: {methods: [:name]}})
            }.merge(changes || {})

            Crm::Api::ExecuteWorker.perform_async('post', 'User', user.id, nil, payload, interakt_base.id.to_s) if interakt_base.present?
            Crm::Api::ExecuteWorker.perform_async('post', 'User', user.id, nil, payload, onesignal_base.id.to_s) if onesignal_base.present?
          end
          # Update primary user details on all company users in case of changes
          if user.role?('cp_owner') && user.channel_partner&.primary_user_id == user.id && (changed_keys = (changes.keys & %w(first_name last_name phone)).presence) && changed_keys&.all? {|key| user[key].present?}
            changed_payload = changed_keys.inject({}) do |hsh, key|
              hsh[key] = changes.dig(key, 1)
              hsh
            end
            user.channel_partner.users.ne(id: user.id).each do |cp_user|
              Crm::Api::ExecuteWorker.perform_async('post', 'User', cp_user.id, nil, { 'primary_owner' => changed_payload }, interakt_base.id.to_s) if interakt_base.present?
              Crm::Api::ExecuteWorker.perform_async('post', 'User', cp_user.id, nil, { 'primary_owner' => changed_payload }, onesignal_base.id.to_s) if onesignal_base.present?
            end
          end

          # For calling Interakt APIs
          if interakt_base
            # Send manager change on channel_partner/cp_owner user
            if changes.has_key?('manager_id') && changes.dig('manager_id', 1).present?
              Crm::Api::ExecuteWorker.perform_async('post', 'User', user.id, 'Manager Changed', changes, interakt_base.id.to_s)
            end
            # Send joined existing company event on channel_partner user
            if changes.has_key?('channel_partner_id') && (channel_partner_id = changes.dig('channel_partner_id', 1).presence) && user.temp_channel_partner_id.present?
              payload = {
                'channel_partner' => ChannelPartner.where(id: channel_partner_id).first&.as_json(include: {primary_user: {methods: [:name]}, manager: {methods: [:name]}})
              }.merge(changes || {})
              Crm::Api::ExecuteWorker.perform_async('post', 'User', user.id, 'Joined Existing Company' , payload, interakt_base.id.to_s)
            end
            # Send account activeness change on channel_partner/cp_owner user
            if changes.has_key?('is_active')
              if changes.dig('is_active', 1).present?
                Crm::Api::ExecuteWorker.perform_async('post', 'User', user.id, 'Account Active', changes, interakt_base.id.to_s)
              elsif changes.dig('is_active', 1).blank?
                Crm::Api::ExecuteWorker.perform_async('post', 'User', user.id, 'Account Inactive', changes, interakt_base.id.to_s)
              end
            end
            # Send manager change on channel_partner/cp_owner user
            if changes.has_key?('sign_in_count') && changes.dig('sign_in_count', 1) == 1
              Crm::Api::ExecuteWorker.perform_async('post', 'User', user.id, 'First Sign In', changes, interakt_base.id.to_s)
            end
          end

        else

          # For calling Interakt APIs
          if interakt_base
            if (changed_keys = (changes.keys & %w(first_name last_name email phone project_ids)).presence) && changed_keys&.all? {|key| user[key].present?}
              Crm::Api::ExecuteWorker.perform_async('post', 'User', user.id, nil, changes, interakt_base.id.to_s)
            end
          end

        end # role check
      end # action check
    end # user present
  end
end
