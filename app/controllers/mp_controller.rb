class MpController < ApplicationController
  before_action :authenticate_user!
  layout "mp/application"
  private

   #
   # Admin controller is only for administrator users.
   #
   #

end
