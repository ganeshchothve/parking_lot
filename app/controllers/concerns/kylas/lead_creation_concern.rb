module Kylas
  module LeadCreationConcern
    extend ActiveSupport::Concern

    included do
      before_action :fetch_deal_details, only: [:new_kylas_associated_lead, :create_kylas_associated_lead]
      before_action :fetch_kylas_products, only: [:new_kylas_associated_lead, :create_kylas_associated_lead]
      before_action :set_project, only: [:create_kylas_associated_lead]
      before_action :set_user, only: [:create_kylas_associated_lead]
    end

    def new_kylas_associated_lead
      @lead = Lead.new(created_by: current_user, kylas_deal_id: params[:entityId])
    end

    def create_kylas_associated_lead
      respond_to do |format|
        if @user.save
          @user.confirm
          create_or_set_lead(format)
        else
          format.html { redirect_to request.referer, alert: (@user.errors.full_messages.uniq.presence || 'Something went wrong') }
        end
      end
    end

    # action used for ajax call
    def deal_associated_contact_details
      contact_id = params[:contact_id]
      @contact_details = Kylas::FetchContactDetails.new(current_user, [contact_id], true).call
      respond_to do |format|
        if @contact_details[:success]
          contact = @contact_details[:data]
          if contact.present?
            format.json { render json: contact, status: :ok }
          else
            format.json { render json: {errors: 'Contact details not present'}, status: :not_found }
          end
        else
          format.json { render json: {errors: @contact_details[:error]}, status: :not_found }
        end
      end
    end

    private

    def user_params
      params.require(:lead).permit(:first_name, :last_name, :email, :phone, :kylas_contact_id)
    end

    def lead_params
      params.require(:lead).permit(:first_name, :last_name, :email, :phone, :kylas_deal_id, :sync_to_kylas)
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
      else
        redirect_to root_path, alert: 'Deal not found'
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
      @project = Project.where(kylas_product_id: kylas_product_id).first
      if @project.present?
        sync_product_to_kylas(current_user, kylas_product_id, kylas_deal_id, @deal_data)
      else
        redirect_to root_path, alert: 'Project not found'
      end
    end

    def set_user
      @user = User.or(get_query).first if get_query.present?
      unless @user.present?
        @user = User.new
        @user.assign_attributes(user_params)
        @user.booking_portal_client = current_user.booking_portal_client
        @user.is_active = false
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
      @lead = Lead.where(kylas_deal_id: params.dig(:lead, :kylas_deal_id), user_id: @user.id, project_id: @project.id).first
      if @lead.blank?
        @lead = @user.leads.build(lead_params)
        @lead.booking_portal_client = current_user.booking_portal_client
        @lead.project = @project
        @lead.created_by = current_user
        @lead.kylas_pipeline_id = (@deal_data.dig(:pipeline, :id).to_s rescue nil)
      end
      if @lead.persisted? || @lead.save
        sync_contact_to_kylas(current_user, @user, @lead.kylas_deal_id, @deal_data) if params.dig(:lead, :sync_to_kylas).present?
        if @project.enable_inventory?
          format.html { redirect_to new_admin_lead_search_path(@lead.id), notice: 'Lead was successfully created' }
        else
          format.html { redirect_to new_booking_without_inventory_admin_booking_details_path(lead_id: @lead.id), notice: 'Lead was successfully created' }
        end
      else
        format.html { redirect_to request.referer, alert: (@lead.errors.full_messages.uniq.presence || 'Something went wrong'), status: :unprocessable_entity }
      end
    end

    # TODO: Create Separate service for sync to Kylas entity
    def sync_contact_to_kylas(current_user, kylas_entity, kylas_deal_id, deal_data)
      params = {}
      contact_response = Kylas::CreateContact.new(current_user, kylas_entity).call
      if deal_data.present? && contact_response.present?
        contact = contact_response[:data] rescue {}
        params.merge!(contact: contact)
        Kylas::UpdateDeal.new(current_user, kylas_deal_id, params).call
      end
    end

    def sync_product_to_kylas(current_user, kylas_product_id, kylas_deal_id, deal_data)
      params = {}
      products_response = Kylas::FetchProducts.new(current_user).call(detail_response = true)
      if deal_data.present? && products_response.present?
        if deal_data['products'].blank? || deal_data['products'].pluck('id').exclude?(kylas_product_id)
          product = (products_response.select{|p| p['id'] == kylas_product_id.to_i }.first rescue {})
          params.merge!(product: product) if product.present?
          Kylas::UpdateDeal.new(current_user, kylas_deal_id, params).call
        end
      end
    end

  end
end