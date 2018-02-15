class UserObserver < Mongoid::Observer
  def before_save user
    unless user.authentication_token?
      user.reset_authentication_token!
    end
  end
end
