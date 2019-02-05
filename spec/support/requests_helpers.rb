module Requests
  module JsonHelpers
    def response_json
      @response_json ||= JSON.parse(response.body)
    end
  end

  module AuthenticateUser
    def sign_in_app(user)
      # project ||= Project.order('created_at DESC').first
      # client ||= Client.order('created_at DESC').first || create(:client)

      # @user = user || FactoryGirl.create(:user)
      sign_in user
    end
  end

end