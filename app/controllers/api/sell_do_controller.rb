class Api::SellDoController < ApplicationController
  skip_before_action :verify_authenticity_token
  include ApplicationHelper

end
