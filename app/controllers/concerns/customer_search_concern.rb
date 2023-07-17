module CustomerSearchConcern

  def authorize_resource
    if params[:action] == 'index'
      authorize [current_user_role_group, CustomerSearch]
    elsif params[:action] == 'new' || params[:action] == 'create'
      authorize [current_user_role_group, CustomerSearch.new()]
    else
      authorize [current_user_role_group, @customer_search]
    end
  end

  def update_step
    @errors = []
    if params[:customer_search].present? && params[:customer_search][:step].present?
      @customer_search.step = params[:customer_search][:step]
    elsif @customer_search.step == 'search'
      search_for_customer
    elsif @customer_search.step == 'customer'
      update_customer
    elsif @customer_search.step == 'kyc'
      update_kyc
    elsif @customer_search.step == 'sitevisit'
      conduct_sitevisit
    end
  end

  def search_for_customer
    if params[:lead_id].present?
      customer = Lead.where(Lead.user_based_scope(current_user, params)).filter_by_lead_id(params[:lead_id]).first
    elsif params[:token_number].present?
      receipt = Receipt.where(Receipt.user_based_scope(current_user, params)).filter_by_token_number(params[:token_number]).first
      customer = receipt.lead if receipt.present?
    elsif params[:code].present?
      site_visit = SiteVisit.where(SiteVisit.user_based_scope(current_user, params)).gre_filter.filter_by_code(params[:code]).first
      if site_visit.present?
        customer = site_visit.lead
        @customer_search.assign_attributes(site_visit_id: site_visit.id)
      end
    elsif params[:_id].present?
      customer = Lead.where(Lead.user_based_scope(current_user, params)).filter_by__id(params[:_id]).first
    end
    if customer.present?
      @customer_search.assign_attributes(customer_id: customer.id)
    end
    @customer_search.assign_attributes(step: 'customer')
  end

  def update_customer
    search_for_customer if @customer_search.customer.blank?
    @lead = @customer_search.customer

    attrs = params.permit(policy([:admin, @lead]).permitted_attributes)
    @lead.update(attrs) if attrs.present?

    @customer_search.assign_attributes(step: 'sitevisit') if @customer_search.customer.present?
  end

  def update_kyc
    @customer_search.assign_attributes(step: 'sitevisit') if @customer_search.user_kyc.present?
  end

  def conduct_sitevisit
    _lead = @customer_search.customer

    if _sitevisit = @customer_search.site_visit.presence
      #
      # Select sitevisit by unique visit code
      #
    elsif params[:sitevisit_id].present?
      #
      # Select sitevisit by id
      #
      _sitevisit = _lead.site_visits.where(booking_portal_client_id: current_client.try(:id), id: params[:sitevisit_id]).in(status: ['scheduled', 'pending']).first

    elsif params[:sitevisit_datetime].present?# && params[:cp_code].present?
      #
      # If no scheduled sitevisit found, then create a new sitevisit
      #
      #_sitevisit = _lead.site_visits.build(scheduled_on: params[:sitevisit_datetime], status: "scheduled", creator: current_user, project: _lead.project, user: _lead.user, scheduled_status: 'proposed')#, cp_code: params[:cp_code])

      attrs = {lead_id: _lead.id.to_s, lead: {site_visits_attributes: {}}}
      attrs[:lead][:site_visits_attributes]['0'] = { scheduled_on: params[:sitevisit_datetime], creator_id: current_user.id, scheduled_status: 'proposed' }

      errors, _lead_manager, _user, _lead, _sitevisit = ::LeadRegistrationService.new(current_client, _lead.project, current_user, attrs).execute
    end

    if _sitevisit.scheduled_on.to_date != Date.current && params[:scheduled_on_now].present?
      _sitevisit.scheduled_on = params[:scheduled_on_now]
    end

    if errors.blank?
      _lead.current_site_visit = _sitevisit

      if _sitevisit.may_conduct?

        _sitevisit.conducted_on = params[:sitevisit_datetime] || Time.current
        _sitevisit.conducted_by = current_user.role

        if _sitevisit.conduct!

          if _lead.save
            SelldoSitevisitUpdateWorker.new.perform(current_client.id, _lead.id, current_user.id, _sitevisit.id, params[:cp_code]) if _lead.lead_id
          else
            @errors += _lead.errors.full_messages
          end

          if !_lead.queued? && _lead.queued!
            @customer_search.assign_attributes(step: 'queued')
          else
            @customer_search.assign_attributes(step: 'not_queued')
          end

        else
          @errors += _sitevisit.errors.full_messages
        end
      end
    else
      @errors += errors
    end
  end
end
