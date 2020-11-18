module SearchesHelper

  def search_next_step_url
    if current_user.buyer?
      @search.persisted? ? user_search_path(@search) : user_searches_path
    else
      @search.persisted? ? admin_lead_search_path(@lead, @search) : admin_lead_searches_path(@lead)
    end
  end
end
