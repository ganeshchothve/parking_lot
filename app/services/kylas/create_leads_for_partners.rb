# frozen_string_literal: true
require 'net/http'

module Kylas
  # service to create deal in kylas
  class CreateLeadsForPartners < BaseService

    attr_accessor :manager_ids, :user, :project, :lead_data, :params

    def initialize(manager_ids, user, project, lead_data, params)
      @manager_ids = manager_ids
      @user = user
      @project = project
      @lead_data = lead_data
      @params = params
    end

    def call
      return if @user.blank? || @project.blank? || @lead_data.blank? || @params.blank?

      count = 0
      errors = {header: 'Could not create leads with following partners', body: []}

      manager_ids.each do |manager_id|
        manager = User.where(id: manager_id, booking_portal_client_id: project.booking_portal_client_id).in(role: %w(channel_partner cp_owner)).first
        if manager.present?
          lead = Lead.new(
            first_name: params.dig(:lead, :first_name),
            last_name: params.dig(:lead, :last_name),
            email: params.dig(:lead, :email),
            phone: params.dig(:lead, :phone),
            booking_portal_client: user.booking_portal_client,
            project: project,
            manager_id: manager.id,
            user: user,
            kylas_lead_id: params[:entityId]
          )
          if lead.save
            Kylas::SyncLeadToKylasWorker.new.perform(lead.id.to_s)
            if (lead_data['products'].blank? || lead_data['products'].pluck('id').map(&:to_s).exclude?(params.dig(:lead, :kylas_product_id))) && count < 1
                response = Kylas::UpdateLead.new(user, lead.kylas_lead_id, params).call
                count += 1 if response[:success]
            end
          else
            errors[:body] << { title: manager._name, messages: lead.errors.full_messages }
          end
        end
      end

      if errors[:body].present?
        { success: false, errors: errors }
      else
        { success: true }
      end
    end
  end
end
