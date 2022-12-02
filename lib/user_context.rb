# Used in Pundit, to pass current client & current project in policies
class UserContext
  attr_reader :user, :current_client, :current_project, :current_domain

  def initialize(user, client=nil, project=nil, domain=nil)
    @user = user
    @current_client = client
    @current_project = project
    @current_domain = domain
  end
end
