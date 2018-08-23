class ChannelPartnersController < ApplicationController
  before_action :authenticate_user!, except: [:new, :create]
  before_action :set_channel_partner, only: [:show, :edit, :update, :destroy]
  around_action :apply_policy_scope
  before_action :authorize_resource

  layout :set_layout

  def index
    @channel_partners = ChannelPartner.build_criteria params
    if params[:fltrs].present? && params[:fltrs][:_id].present?
      redirect_to edit_channel_partner_path(params[:fltrs][:_id])
    else
      @channel_partners = @channel_partners.paginate(page: params[:page] || 1, per_page: 15)
    end
  end

  def export
    if Rails.env.development?
      ChannelPartnerExportWorker.new.perform(current_user.id.to_s)
    else
      ChannelPartnerExportWorker.perform_async(current_user.id.to_s)
    end
    flash[:notice] = 'Your export has been scheduled and will be emailed to you in some time'
    redirect_to channel_partners_path
  end

  def show
  end

  def new
    @channel_partner = ChannelPartner.new
  end

  def edit
    render layout: false
  end

  def create
    @channel_partner = ChannelPartner.new(permitted_attributes(ChannelPartner.new))

    respond_to do |format|
      if @channel_partner.save
        ChannelPartnerMailer.send_create(@channel_partner.id).deliver
        format.html { redirect_to (user_signed_in? ? channel_partners_path : root_path), notice: 'Channel partner was successfully created.' }
        format.json { render json: @channel_partner, status: :created }
      else
        format.html { render :new }
        format.json { render json: {errors: @channel_partner.errors.full_messages.uniq}, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @channel_partner.update(permitted_attributes(@channel_partner))
        format.html { redirect_to channel_partners_path, notice: 'Channel partner was successfully updated.' }
        format.json { render json: @channel_partner }
      else
        format.html { render :edit }
        format.json { render json: {errors: @channel_partner.errors.full_messages.uniq}, status: :unprocessable_entity }
      end
    end
  end

  private
  def set_channel_partner
    @channel_partner = ChannelPartner.find(params[:id])
  end

  def authorize_resource
    if params[:action] == "index" || params[:action] == 'export'
      authorize ChannelPartner
    elsif params[:action] == "new"
      authorize ChannelPartner.new
    elsif params[:action] == "create"
      authorize ChannelPartner.new(permitted_attributes(ChannelPartner.new))
    else
      authorize @channel_partner
    end
  end

  def apply_policy_scope
    custom_scope = ChannelPartner.all.criteria
    ChannelPartner.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
