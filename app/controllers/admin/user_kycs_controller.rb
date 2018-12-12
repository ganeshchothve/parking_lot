# TODO: replace all messages & flash messages
class Admin::UserKycsController < ApplicationController
  include UserKycsConcern
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_user_kyc, only: %i[show edit update destroy]
  around_action :apply_policy_scope
  before_action :authorize_resource

  layout :set_layout

  # index new and the rest of the functions are defined in UserKycsConcern
  def set_user_creator
    @user_kyc.user = @user
    @user_kyc.creator = current_user
  end

  private

  def authorize_resource
    if params[:action] == 'index'
      authorize [:admin, UserKyc]
    elsif params[:action] == 'new'
      authorize [:admin, UserKyc.new(user: @user)]
    elsif params[:action] == 'create'
      authorize [:admin, UserKyc.new(permitted_attributes(UserKyc.new(user: @user)))]
    else
      authorize [:admin, @user_kyc]
    end
  end
end
