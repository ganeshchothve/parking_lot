class ChannelPartnersController < ApplicationController
  before_action :authenticate_user!, except: %i[new create]
  before_action :set_channel_partner, only: %i[show edit update destroy change_state]
  around_action :apply_policy_scope, only: :index
  before_action :authorize_resource, except: [:new, :create]

  def index
    @channel_partners = ChannelPartner.build_criteria params
    @channel_partners = @channel_partners.paginate(page: params[:page], per_page: params[:per_page])
  end

  def show
    @resource = @channel_partner
  end

  def export
    if Rails.env.development?
      ChannelPartnerExportWorker.new.perform(current_user.id.to_s, params[:fltrs])
    else
      ChannelPartnerExportWorker.perform_async(current_user.id.to_s, params[:fltrs].as_json)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to channel_partners_path(fltrs: params[:fltrs].as_json)
  end

  def new
    @channel_partner = ChannelPartner.new
    render layout: 'devise'
  end

  def edit
    render layout: false
  end

  def create
    @channel_partner = ChannelPartner.new(permitted_attributes([:admin, ChannelPartner.new]))

    respond_to do |format|
      if @channel_partner.save
        format.html { redirect_to (user_signed_in? ? channel_partners_path : root_path), notice: 'Channel partner was successfully created.' }
        format.json { render json: @channel_partner, status: :created }
      else
        flash.now[:alert] = @channel_partner.errors.full_messages.uniq
        format.html { render :new, layout: 'devise', status: :unprocessable_entity}
        format.json { render json: { errors: @channel_partner.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize([:admin, @channel_partner])
    @channel_partner.assign_attributes(permitted_attributes([:admin, @channel_partner]))
    respond_to do |format|
      if (params.dig(:channel_partner, :event).present? ? @channel_partner.send("#{params.dig(:channel_partner, :event)}!") : @channel_partner.save)
        format.html { redirect_to channel_partners_path, notice: 'Channel Partner was successfully updated.' }
        format.json { render json: @channel_partner }
      else
        format.html { render :edit }
        format.json { render json: { errors: @channel_partner.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def change_state
    respond_to do |format|
      if params.dig(:channel_partner, :event).present? && @channel_partner.send("#{params.dig(:channel_partner, :event)}!")
        format.html { redirect_to request.referer, notice: t("controller.channel_partners.status_message.#{@channel_partner.status}") }
      else
        format.html { redirect_to request.referer, alert: (@channel_partner.errors.full_messages.uniq.presence || 'Something went wrong') }
        format.json { render json: { errors: (@channel_partner.errors.full_messages.uniq.presence || 'Something went wrong') }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_channel_partner
    @channel_partner = ChannelPartner.find(params[:id])
  end

  def authorize_resource
    if params[:action] == 'index' || params[:action] == 'export'
      authorize [:admin, ChannelPartner]
    elsif params[:action] == 'new'
      authorize [:admin, ChannelPartner.new]
    elsif params[:action] == 'create'
      authorize [:admin, ChannelPartner.new(permitted_attributes([:admin, ChannelPartner.new]))]
    else
      authorize [:admin, @channel_partner]
    end
  end

  def apply_policy_scope
    custom_scope = ChannelPartner.where(ChannelPartner.user_based_scope(current_user, params))
    ChannelPartner.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
