# TODO: replace all messages & flash messages
class Buyer::UserKycsController < BuyerController
  include UserKycsConcern
  before_action :set_lead, except: %i[index show edit]
  before_action :set_user_kyc, only: %i[show edit update destroy]
  around_action :apply_policy_scope
  before_action :authorize_resource, except: %i[create]

  layout :set_layout

  # set_lead, set_user_kyc and apply_policy_scope are defined in UserKycsConcern

  # index defined in UserKycsConcern
  # GET /buyer/user_kycs

  # new defined in UserKycsConcern
  # GET /buyer/user_kycs/new

  # create defined in UserKycsConcern
  # POST /buyer/user_kycs

  # edit defined in UserKycsConcern
  # GET /buyer/user_kycs/:id/edit

  # update defined in UserKycsConcern
  # PATCH /buyer/user_kycs/:id

  # This action is to set the user and creator as current_user for the user kyc record.
  #
  def set_user_creator
    @user_kyc.user = @user_kyc.creator = current_user
  end

  private

  def authorize_resource
    if params[:action] == 'index'
      authorize [:buyer, UserKyc]
    elsif params[:action] == 'new'
      authorize [:buyer, UserKyc.new(user: @lead.user, lead: @lead)]
    else
      authorize [:buyer, @user_kyc]
    end
  end
end
