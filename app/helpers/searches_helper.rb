module SearchesHelper

  def search_next_step_url
    if current_user.buyer?
      @search.persisted? ? search_path(@search) : searches_path(lead_id: @search.lead_id)
    else
      @search.persisted? ? admin_lead_search_path(@lead, @search) : admin_lead_searches_path(@lead)
    end
  end
end
