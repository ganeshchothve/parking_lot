class BuyerController < ApplicationController
  before_action :authenticate_user!
  before_action :only_buyer_users!

  private

   #
   # Admin controller is only for administrator users.
   #
   #
   def only_buyer_users!
    if !current_user.buyer?
      redirect_to dashboard_path, alert: t('controller.only_buyer_users')
    end
   end
end
