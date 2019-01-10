class ChannelPartnerPolicy < ApplicationPolicy
  # def index? def create? def new? def update? def edit? def permitted_attributes from ApplicationPolicy

  def export?
    index?
  end
end
