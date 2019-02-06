module AccountConcern

  def associated_class
    @associated_class = Account::RazorpayPayment
  end
  
  def set_account
    @account = associated_class.find(params[:id])
  end

	def authorize_resource
    if params[:action] == 'index'
      authorize [current_user_role_group, Account]
    elsif params[:action] == 'new' || params[:action] == 'create'
      authorize [current_user_role_group, Account::RazorpayPayment.new()]
    else
      @account = associated_class.find(params[:id])
      authorize [current_user_role_group, @account]
    end
  end
end
