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
    if params[:lead].present?
      @lead.update(permitted_attributes([:admin, @lead]))
    end
    if params[:manager_id].present?
      cp_user = User.all.channel_partner.where(id: params[:manager_id]).first
      cp_lead_activity = CpLeadActivityRegister.create_cp_lead_object(@lead, cp_user)
      cp_lead_activity.save if cp_lead_activity.present?
    end
    @customer_search.assign_attributes(step: 'sitevisit') if @customer_search.customer.present?
  end

  def update_kyc
    @customer_search.assign_attributes(step: 'sitevisit') if @customer_search.user_kyc.present?
  end

  def conduct_sitevisit
    _lead = @customer_search.customer
    if params[:sitevisit_datetime].present?# && params[:cp_code].present?
      _sitevisit = _lead.site_visits.build(scheduled_on: params[:sitevisit_datetime], status: "scheduled", creator: current_user, project: _lead.project, user: _lead.user)#, cp_code: params[:cp_code])
      _sitevisit.is_revisit = _lead.is_revisit?
    elsif params[:sitevisit_id].present?
      _sitevisit = _lead.site_visits.where(id: params[:sitevisit_id]).first
      _sitevisit.status = 'scheduled' if _sitevisit.present?
    end
    _lead.current_site_visit = _sitevisit
    _sitevisit.save
    #if _sitevisit.try(:cp_code).present?# && !_lead.permanently_blocked? && !_lead.temporarily_blocked
    #  channel_partner = ChannelPartner.where(cp_portal_id: _sitevisit.cp_code).first
    #  _lead.temporarily_block_manager(channel_partner.associated_user_id) if channel_partner.present?
    #end

    SelldoSitevisitUpdateWorker.new.perform(_lead.id, current_user.id, _sitevisit.id, params[:cp_code]) if _lead.save && _lead.lead_id && _sitevisit.present?

    if !_lead.queued? && _lead.queued!
      @customer_search.assign_attributes(step: 'queued')
    else
      @customer_search.assign_attributes(step: 'not_queued')
    end
  end
end
