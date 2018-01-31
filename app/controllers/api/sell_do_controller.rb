class Api::SellDoController < ApplicationController
  skip_before_action :verify_authenticity_token
	before_action :check_client_id

  def create_developer
    developer = Developer.where(selldo_id: @parameters["_id"]).first rescue nil
    developer ||= Developer.new(selldo_id: @parameters["_id"])
    if developer.update_attributes(@parameters)
      render :json => {"status" => "Developer saved successfully"}, status: 200
    else
      render :json => {"status" => "Error in saving Developer details", "errors" =>  developer.errors.full_messages}, status: 422
    end
  end

	def create_project
		project = Project.unscoped.find_by(selldo_id: @parameters["_id"]) rescue nil
    project ||= Project.new(selldo_id: @parameters["_id"])
		if project.update_attributes(@parameters)
			render :json => {"status" => "Project saved successfully"}, status: 200
		else
			render :json => {"status" => "Error in saving Project details", "errors" =>  project.errors.full_messages}, status: 422
		end
	end

	def create_project_tower
		project_tower = ProjectTower.unscoped.find_by(selldo_id: @parameters["_id"]) rescue nil
		project_tower ||= ProjectTower.new(selldo_id: @parameters["_id"])
    if project_tower.update_attributes(@parameters)
			render :json => {"status" => "Project Tower saved successfully."}, status: 200
		else
			render :json => {"status" => "Error in saving Project Tower details", "errors" =>  project_tower.errors.full_messages}, status: 422
		end
	end

	def create_uc
		uc = UnitConfiguration.unscoped.find_by(selldo_id: @parameters["_id"]) rescue nil
		uc ||= UnitConfiguration.new(selldo_id: @parameters["_id"])
		if uc.update_attributes(@parameters)
			render :json => {"status" => "Unit Configuration saved successfully."}, status: 200
		else
			render :json => {"status" => "Error in saving Unit Configuration details. #{parent_error}", "errors" =>  uc.errors.full_messages}, status: 422
		end
	end

  def create_project_unit
		project_unit = ProjectUnit.unscoped.find_by(selldo_id: @parameters["_id"]) rescue nil
		project_unit ||= ProjectUnit.new(selldo_id: @parameters["_id"])
		if project_unit.update_attributes(@parameters)
			render :json => {"status" => "Project Unit saved successfully. "}, status: 200
		else
			render :json => {"status" => "Error in saving Project Unit details. ", "errors" =>  project_unit.errors.full_messages}, status: 422
		end
	end

	private
	def check_client_id
		if params[:project].present?
			@parameters = JSON(params[:project])
    elsif params[:developer].present?
			@parameters = JSON(params[:developer])
		elsif params[:uc].present?
			@parameters = JSON(params[:uc])
		elsif params[:project_unit].present?
			@parameters = JSON(params[:project_unit])
		elsif params[:project_tower].present?
			@parameters = JSON(params[:project_tower])
		else
			render :json => {"status" => "Error: params not present", "errors" =>  ["Project params not present"]}, status: 422
			return
		end
		if @parameters.present?
      ["brochure_template_ids", "copy_payment_schedule", "interested_property_id", "job_id", "price_quote_sent", "price_quote_template_ids", "brochure_template_ids", "release_at", "contact", "incentive_plan_ids", "ivr_phone", "vr", "vr_id", "project_post_sale_ids", "sales_id", "sync_data", "project_pre_sale_ids", "reference_id", "reference_name", "brochure_sent"].each do |key|
        @parameters.delete(key)
      end
			unless @parameters["client_id"].to_s == client_id
				render :json => {"status" => "Error: Client Id does not match", "errors" =>  ["Client Id does not match"]}, status: 422
				return
			end
		end
	end

  def client_id
    ""
  end
end
