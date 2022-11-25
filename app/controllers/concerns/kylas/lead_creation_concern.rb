module Kylas
  module LeadCreationConcern
    extend ActiveSupport::Concern

    included do
      before_action :fetch_deal_details, only: [:new_kylas_associated_lead, :create_kylas_associated_lead]
      before_action :fetch_kylas_products, only: [:new_kylas_associated_lead, :create_kylas_associated_lead, :new_kylas_lead]
      before_action :set_project, only: [:create_kylas_associated_lead, :create_kylas_lead]
      before_action :set_user, only: [:create_kylas_associated_lead, :create_kylas_lead]
      before_action :fetch_lead_details, only: [:new_kylas_lead, :create_kylas_lead]
      before_action :redirect_to_checkout, only: [:new_kylas_associated_lead]
    end

    def new_kylas_associated_lead
      @lead = Lead.new(created_by: current_user, kylas_deal_id: params[:entityId])
    end

    def create_kylas_associated_lead
      respond_to do |format|
        if @user.valid?
          if @user.save
            @user.set(kylas_contact_id: params.dig(:lead, :kylas_contact_id)) if params.dig(:lead, :kylas_contact_id).present?
            Kylas::UpdateContact.new(current_user, @user, {check_uniqueness: true}).call if params.dig(:lead, :kylas_contact_id).present? && (params.dig(:lead, :phone_update).present? || params.dig(:lead, :email_update).present?)
            Kylas::CreateContact.new(current_user, @user, {check_uniqueness: true, run_in_background: false}) if params.dig(:lead, :sync_to_kylas).present?
            @user.confirm
            create_or_set_lead(format)
          else
            format.html { redirect_to request.referer, alert: (@user.errors.full_messages.uniq.presence || 'Something went wrong') }
          end
        else
          format.html { redirect_to request.referer, alert: (@user.errors.full_messages.uniq.presence || 'Something went wrong') }
        end
      end
    end

    def new_kylas_lead
      @lead = Lead.new
    end

    def create_kylas_lead
      respond_to do |format|
        if @user.valid?
          @user.skip_confirmation_notification!
          @user.save
          manager_ids = params.dig(:lead, :manager_ids)

          count = 0
          manager_ids.each do |manager_id|
            manager = User.where(id: manager_id).first
            if manager.present?
              @lead = Lead.new(
                              first_name: params.dig(:lead, :first_name),
                              last_name: params.dig(:lead, :last_name),
                              email: params.dig(:lead, :email),
                              phone: params.dig(:lead, :phone),
                              booking_portal_client: current_client,
                              project: @project,
                              manager_id: manager.id,
                              user: @user,
                              kylas_lead_id: params[:entityId]
                              )

              if @lead.save
                Kylas::SyncLeadToKylasWorker.perform_async(lead.id.to_s)
                if (@lead_data['products'].blank? || @lead_data['products'].pluck('id').map(&:to_s).exclude?(params.dig(:lead, :kylas_product_id))) && count < 1
                    response = Kylas::UpdateLead.new(current_user, @lead.kylas_lead_id, params).call
                    count += 1 if response[:success]
                end
              end
            end
          end
          format.html { redirect_to request.referer, notice: 'Leads were successfully created' }
        else
          format.html { redirect_to request.referer, alert: @user.errors.full_messages }
        end
      end
    end

    private

    def user_params
      params.require(:lead).permit(:first_name, :last_name, :email, :phone, :kylas_contact_id)
    end

    def lead_params
      params.require(:lead).permit(:first_name, :last_name, :email, :phone, :kylas_deal_id, :sync_to_kylas, :manager_id)
    end

    def fetch_deal_details
      entity_id = params[:entityId] || params.dig(:lead, :kylas_deal_id)
      fetch_deal_details = Kylas::FetchDealDetails.new(entity_id, current_user).call
      if fetch_deal_details[:success]
        @deal_data = fetch_deal_details[:data].with_indifferent_access
        @deal_associated_products = @deal_data[:products].collect{|pd| [pd[:name], pd[:id]]} rescue []
        kylas_product_ids = current_user.booking_portal_client.projects.pluck(:kylas_product_id).compact.map(&:to_i)
        @deal_associated_products = @deal_associated_products.select{|kp| kylas_product_ids.include?(kp[1]) } rescue []
        @deal_associated_contacts = @deal_data[:associatedContacts].collect{|pd| [pd[:name], pd[:id]]} rescue []
        contact_ids = @deal_data[:associatedContacts].pluck(:id) rescue []
        @contact_details = Kylas::FetchContactDetails.new(current_user, contact_ids).call rescue {}
        @kylas_emails = @contact_details.dig(:data).pluck(:emails).flatten rescue []
        @kylas_phones = @contact_details.dig(:data).pluck(:phoneNumbers).flatten rescue []
        @kylas_cp_id = @deal_data.dig(:customFieldValues, :cfChannelPartner, :id)
        if @kylas_cp_id.present?
          @cp_users = User.in(role: ['channel_partner', 'cp_owner']).where(booking_portal_client_id: current_user.booking_portal_client_id, user_status_in_company: 'active', 'kylas_custom_fields_option_id.deals': @kylas_cp_id)
        end
      else
        redirect_to root_path, alert: 'Deal not found'
      end
    end

    def fetch_lead_details
      entity_id = params[:entityId]
      fetch_lead_details = Kylas::FetchLeadDetails.new(entity_id, current_user).call
      if fetch_lead_details[:success]
        @lead_data = fetch_lead_details[:data].with_indifferent_access
        @lead_associated_products = @lead_data[:products].collect{|pd| [pd[:name], pd[:id]]} rescue []
        kylas_product_ids = current_user.booking_portal_client.projects.pluck(:kylas_product_id).compact.map(&:to_i)
        @lead_associated_products = @lead_associated_products.select{|kp| kylas_product_ids.include?(kp[1]) } rescue []
      end
    end

    def fetch_kylas_products
      @kylas_products = Kylas::FetchProducts.new(current_user).call
      kylas_product_ids = current_user.booking_portal_client.projects.pluck(:kylas_product_id).compact.map(&:to_i) rescue []
      @kylas_products = @kylas_products.select{|kp| kylas_product_ids.include?(kp[1]) } rescue []
    end

    def set_project
      kylas_product_id = params.dig(:lead, :kylas_product_id)
      kylas_deal_id = params.dig(:lead, :kylas_deal_id)
      @project = Project.where(booking_portal_client_id: current_client.try(:id), kylas_product_id: kylas_product_id).first
      if @project.present?
        sync_product_to_kylas(current_user, kylas_product_id, kylas_deal_id, @deal_data)
      else
        redirect_to root_path, alert: 'Project not found'
      end
    end

    def set_user
      @user = User.or(get_query).where(booking_portal_client_id: current_client.id).first if get_query.present?
      unless @user.present?
        @user = User.new
        @user.assign_attributes(user_params)
        @user.booking_portal_client = current_user.booking_portal_client
        @user.created_by = current_user
      end
    end

    def get_query
      query = []
      query << {email: params.dig(:lead, :email)} if params.dig(:lead, :email).present?
      query << {phone: params.dig(:lead, :phone)} if params.dig(:lead, :phone).present?
      query
    end


    def create_or_set_lead(format)
      @lead = Lead.where(booking_portal_client_id: current_client.try(:id), kylas_deal_id: params.dig(:lead, :kylas_deal_id), user_id: @user.id, project_id: @project.id).first
      if @lead.blank?
        @lead = @user.leads.build(lead_params)
        @lead.booking_portal_client = current_user.booking_portal_client
        @lead.project = @project
        @lead.created_by = current_user
        @lead.kylas_pipeline_id = (@deal_data.dig(:pipeline, :id).to_s rescue nil)
      end
      @lead.assign_attributes(manager_id: params.dig(:lead, :manager_id)) if (@lead.manager_id.to_s != params.dig(:lead, :manager_id))
      if @lead.valid?
        options = {current_user: current_user, kylas_deal_id: params.dig(:lead, :kylas_deal_id), deal_data: @deal_data}
        associate_contact_with_deal(format, options) if params.dig(:lead, :sync_to_kylas).present?
        if @lead.save
          project = Project.where(kylas_product_id: params.dig(:lead, :kylas_product_id)).first
          if project.present? && project.bookings_enabled?
            if @project.enable_inventory?
              format.html { redirect_to new_admin_lead_search_path(@lead.id), notice: 'Lead was successfully created' }
            else
              format.html { redirect_to new_booking_without_inventory_admin_booking_details_path(lead_id: @lead.id), notice: 'Lead was successfully created' }
            end
          else
            format.html { redirect_to request.referer, alert: ('Bookings on this project is disabled') }  
          end
        else
          format.html { redirect_to request.referer, alert: (@lead.errors.full_messages.uniq.presence || 'Something went wrong'), status: :unprocessable_entity }
        end
      else
        format.html { redirect_to request.referer, alert: (@lead.errors.full_messages.uniq.presence || 'Something went wrong'), status: :unprocessable_entity }
      end
    end

    def associate_contact_with_deal(format, options = {})
      deal_payload = {}
      deal_data = options[:deal_data]
      current_user = options[:current_user]
      kylas_deal_id = options[:kylas_deal_id]
      if deal_data.present?
        deal_payload.merge!({run_in_background: true})
        Kylas::UpdateDeal.new(current_user, @lead, deal_payload).call
      else
        format.html { redirect_to request.referer, alert: 'Something went wrong', status: :unprocessable_entity }
      end
    end

    def sync_product_to_kylas(current_user, kylas_product_id, kylas_deal_id, deal_data)
      update_deal_payload = {}
      products_response = Kylas::FetchProducts.new(current_user).call(detail_response = true)
      if deal_data.present? && products_response.present?
        if deal_data['products'].blank? || deal_data['products'].pluck('id').exclude?(kylas_product_id.to_i)
          product = (products_response.select{|p| p['id'] == kylas_product_id.to_i }.first rescue {})
          update_deal_payload.merge!(product: product, run_in_background: true) if product.present?
          lead = Lead.where(kylas_deal_id: kylas_deal_id, booking_portal_client_id: current_user.booking_portal_client.id).first if kylas_deal_id.present?
          Kylas::UpdateDeal.new(current_user, lead, update_deal_payload).call if lead.present?
        end
      end
    end

    private

    def redirect_to_checkout
      lead_ids = Lead.where(booking_portal_client_id: current_client.try(:id), kylas_deal_id: params[:entityId]).pluck(:id)
      hold_booking = BookingDetail.in(lead_id: lead_ids).hold.first
      if hold_booking.present?
        respond_to do |format|
          format.html { redirect_to checkout_lead_search_path(hold_booking.search) }
        end
      end
    end

  end
end
