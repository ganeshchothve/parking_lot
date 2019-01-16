# TODO: replace all messages & flash messages
class Admin::UserKycsController < AdminController
  include UserKycsConcern
  before_action :set_user
  before_action :set_user_kyc, only: %i[show edit update destroy]
  around_action :apply_policy_scope
  before_action :authorize_resource

  layout :set_layout

  # set_user, set_user_kyc and apply_policy_scope are defined in UserKycsConcern

  # index defined in UserKycsConcern
  # GET /admin/users/:user_id/user_kycs
  # GET /admin/user_kycs

  # new defined in UserKycsConcern
  # GET /admin/users/:user_id/user_kycs/new

  # create defined in UserKycsConcern
  # POST /admin/users/:user_id/user_kycs

  # edit defined in UserKycsConcern
  # GET /admin/users/:user_id/user_kycs/:id/edit

  # update defined in UserKycsConcern
  # PATCH /admin/users/:user_id/user_kycs/:id
  
  # This action is to set the creator as Admin for the user kyc record of the user.
  #
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
      authorize [:admin, UserKyc.new(permitted_attributes([:admin, UserKyc.new(user: @user)]))]
    else
      authorize [:admin, @user_kyc]
    end
  end
end