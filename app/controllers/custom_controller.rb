class CustomController < ApplicationController
  include CustomConcern
  before_action :authenticate_user!
  layout :set_layout

end
