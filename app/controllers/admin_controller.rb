class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :only_administrator_users!, except: [:choose_template_for_print, :print_template]

  private

   #
   # Admin controller is only for administrator users.
   #
   #
   def only_administrator_users!
    if current_user && current_user.buyer? && params[:controller] != 'admin/schemes'
      redirect_to home_path(current_user), alert: t('controller.only_administrator_users')
    end
   end
end
