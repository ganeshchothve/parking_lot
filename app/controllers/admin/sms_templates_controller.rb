class Admin::SmsTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_sms_template, except: [:index]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: [:index]

  layout :set_layout

  def index
    @sms_templates = SmsTemplate.build_criteria params
    @sms_templates = @sms_templates.paginate(page: params[:page] || 1, per_page: 15)
    respond_to do |format|
      if params[:ds].to_s == 'true'
        format.json { render json: @sms_templates.collect{|d| {id: d.id, name: d.name}} }
        format.html {}
      else
        format.json { render json: @sms_templates }
        format.html {}
      end
    end
  end

  def edit
    render layout: false
  end

  def update
    @sms_template.assign_attributes(permitted_attributes(@sms_template))
    respond_to do |format|
      if @sms_template.save
        format.html { redirect_to admin_client_sms_templates_path, notice: 'SmsTemplate was successfully updated.' }
        format.json { render json: @sms_template }
      else
        format.html { render :edit }
        format.json { render json: {errors: @sms_template.errors.full_messages.uniq}, status: :unprocessable_entity }
      end
    end
  end

  private
  def set_sms_template
    @sms_template = SmsTemplate.find(params[:id])
  end

  def authorize_resource
    if params[:action] == "index"
      authorize SmsTemplate
    else
      authorize @sms_template
    end
  end

  def apply_policy_scope
    custom_scope = SmsTemplate.all.criteria
    SmsTemplate.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
