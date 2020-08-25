class DocumentSignPolicy < ApplicationPolicy
  def permitted_attributes params={}
    [:id, :access_token, :token_type, :refresh_token, :expires_in, :redirect_url, :vendor_class]
  end
end
