class Mp::DashboardController < ApplicationController
  before_action :authenticate_user!

  def about; end
end