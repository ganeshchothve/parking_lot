class Api::SellDoController < ApisController
  skip_before_action :verify_authenticity_token
end
