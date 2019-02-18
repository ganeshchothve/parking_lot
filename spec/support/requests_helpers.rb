module Requests
  module JsonHelpers
    def response_json
      @response_json ||= JSON.parse(response.body)
    end
  end

  module AuthenticateUser
    def sign_in_app(user=nil, project=nil, client=nil)
      # project ||= Project.order('created_at DESC').first
      # client ||= Client.order('created_at DESC').first || create(:client)

      @user = user || create(:user)
      sign_in @user
    end
  end

end