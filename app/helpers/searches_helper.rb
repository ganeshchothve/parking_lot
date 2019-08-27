module SearchesHelper

  def search_next_step_url
    if current_user.buyer?
      @search.persisted? ? user_search_path(@search) : user_searches_path
    else
      @search.persisted? ? admin_user_search_path(@user, @search) : admin_user_searches_path(@user)
    end
  end
end