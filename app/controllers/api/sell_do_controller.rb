class Api::SellDoController < ApplicationController
  skip_before_action :verify_authenticity_token
	before_action :prepare_parameters
  before_action :check_client_id

  def update
    @object = @klass.where(selldo_id: @parameters["_id"]).first rescue nil
    @object ||= @klass.new(selldo_id: @parameters["_id"])
    if @object.update_attributes(@parameters)
      render :json => {status: "#{@klass} saved successfully"}, status: 200
    else
      render :json => {status: "Error in saving #{@klass}", errors: @object.errors.full_messages}, status: 422
    end
  end

	private
	def check_client_id
		unless @parameters["client_id"].to_s == client_id
      render :json => {"status" => "Error: Client Id does not match", "errors" =>  ["Client Id does not match"]}, status: 422
      return
		end
	end

  def prepare_parameters
    if params[:developer].present? && params[:action] == "create_developer"
      @parameters = JSON(params[:developer])
      @klass = Developer
    elsif params[:project].present? && params[:action] == "create_project"
			@parameters = JSON(params[:project])
      @klass = Project
    elsif params[:project_tower].present? && params[:action] == "create_project_tower"
      @parameters = JSON(params[:project_tower])
      @klass = ProjectTower
		elsif params[:unit_configuration].present? && params[:action] == "create_unit_configuration"
			@parameters = JSON(params[:unit_configuration])
      @klass = UnitConfiguration
		elsif params[:project_unit].present? && params[:action] == "create_project_unit"
			@parameters = JSON(params[:project_unit])
      @klass = ProjectUnit
		else
			render :json => {"status" => "Error: params not present", "errors" =>  ["Project params not present"]}, status: 422
			return
		end
    ["brochure_template_ids", "copy_payment_schedule", "interested_property_id", "job_id", "price_quote_sent", "price_quote_template_ids", "brochure_template_ids", "release_at", "contact", "incentive_plan_ids", "ivr_phone", "vr", "vr_id", "project_post_sale_ids", "sales_id", "sync_data", "project_pre_sale_ids", "reference_id", "reference_name", "brochure_sent"].each do |key|
      @parameters.delete(key)
    end
  end

  def client_id
    ""
  end
end
