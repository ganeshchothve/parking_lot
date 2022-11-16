# Used in Pundit, to pass current client & current project in policies
class UserContext
  attr_reader :user, :current_client, :current_project

  def initialize(user, client=nil, project=nil)
    @user = user
    @current_client = client
    @current_project = project
  end
end
