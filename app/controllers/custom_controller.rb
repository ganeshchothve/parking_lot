class CustomController < ApplicationController
  before_action :authenticate_user!
  layout :set_layout

end
