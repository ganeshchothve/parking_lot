CLIENT_ID = ""
class Api::SellDoController < ApplicationController
	before_action :check_client_id

	def create_project
		project =Project.unscoped.find_by(selldo_id: @obj["_id"]) rescue nil
		if project.nil?
			projectstatus=false
			project = Project.new(selldo_id: @obj["_id"])
		end
		projectstatus||=true
		@obj.except("_id").keys.each do |key|
			project.send("#{key}=", @obj[key]) if project.respond_to?("#{key}")
		end
		project.locality = project.locality.gsub(/pune|bengaluru/i, "").strip if project.locality.present?
		# Taking care of case sensitive values - Extra Spacious/Extra spacious
		project.apartment_size = project.apartment_size.titleize if project.apartment_size.present?
		if project.approved_banks.present?
			if project.approved_banks.is_a?(String)
				project.approved_banks = project.approved_banks.collect{|a|a.upcase}
			else project.approved_banks.is_a?(Array)
				project.approved_banks = project.approved_banks.collect{|a|a.map(&:upcase)}
			end
		end

		project.dedicated_project_phone = "+" + project.dedicated_project_phone if project.dedicated_project_phone.present? && !(project.dedicated_project_phone.include?("+"))

		if projectstatus==true
			project.address.selldo_id = @obj["address"]["_id"] if @obj["address"].present?
			project.address.city = project.address.city.titleize.strip if project.address.present?
		end
		if project.save
			#update unit configs code begins here
			project.compute_area_price
			project.save
			project.unit_configurations.each do |uc|
				uc.send("city=", project.city.titleize.strip) if project.city.present?
				uc.send("segment=", project.project_segment)
				uc.send("project_size=", project.project_size)
				uc.send("apartment_size=", project.apartment_size)
				uc.send("zone=", project.zone)
				uc.send("administration=", project.administration)
				uc.send("possession=", Time.parse(project.possession.to_s)) if project.possession.present?
				uc.send("approved_banks=", project.approved_banks)
				uc.send("approval=", project.approval)
				uc.send("launched_on=", Time.parse(project.launched_on.to_s)) if project.launched_on.present?
				uc.send("tag=", project.suitable_for) if project.suitable_for == "investors"
				uc.send("locality=", (project.locality.gsub(/pune|bengaluru/i, "").strip rescue project.locality))
				uc.send("project_status=", project.project_status)
				project_status_order = PROJECT_STATUS_ORDER.index(project.project_status)
				uc.send("project_status_order=", project_status_order + 1) if project_status_order.present?
				uc.is_active = project.is_active
				uc.unit_configuration_active = "No" if project.is_active == false
				uc.promoted = true if project.promoted == "yes"
				uc.send("secondary_developer_ids=", project.secondary_developer_ids)
				uc.send("secondary_developer_names=", project.secondary_developer_names)
			end
			render :json => {"status" => "Project saved successfully"}, status: 200
		else
			render :json => {"status" => "Error in saving Project details", "errors" =>  project.errors.full_messages}, status: 500
		end
	end

	def create_project_tower
		project_tower = ProjectTower.unscoped.find_by(selldo_id: @obj["_id"]) rescue nil
		project_tower ||= ProjectTower.new(selldo_id: @obj["_id"])
		@obj.except("_id").keys.each do |key|
			project_tower.send("#{key}=", @obj[key]) if project_tower.respond_to?("#{key}")
			logger.info "=================#{key}============#{@obj[key]}"
		end
		logger.info "=============================#{project_tower.inspect}"
		if project_tower.save
			#update project unit configurations
			project_tower.unit_configurations.each do |uc|
				uc.data_attributes.push({"n" => "project_tower_name", "v" => project_tower.name})
				uc.data_attributes.push({"n" => "project_name", "v" => @project.name})
				uc.save
			end
			render :json => {"status" => "Project Tower saved successfully."}, status: 200
		else
			render :json => {"status" => "Error in saving Project Tower details", "errors" =>  project_tower.errors.full_messages}, status: 500
		end
	end

	def create_project_unit

		project_unit = ProjectUnit.unscoped.find_by(selldo_id: @obj["_id"]) rescue nil
		project_unit ||= ProjectUnit.new(selldo_id: @obj["_id"])
		@obj.except("_id").keys.each do |key|
			project_unit.send("#{key}=", @obj[key]) if project_unit.respond_to?("#{key}")
		end
		project_unit.send("city=", project_unit.city.titleize.strip) if project_unit.city.present?
		if project_unit.save
			render :json => {"status" => "Project Unit saved successfully. "}, status: 200
		else
			render :json => {"status" => "Error in saving Project Unit details. ", "errors" =>  project_unit.errors.full_messages}, status: 500
		end
	end

	def create_uc

		uc = UnitConfiguration.unscoped.find_by(selldo_id: @obj["_id"]) rescue nil
		uc ||= UnitConfiguration.new(selldo_id: @obj["_id"])

		@obj.except("_id").keys.each do |key|
			uc.send("#{key}=", @obj[key]) if uc.respond_to?("#{key}")
		end
		uc.send("city=", uc.city.titleize.strip) if uc.city.present?
		uc.send("amenities=", uc.amenities) rescue ''
		parent_error = ""
		if !(uc.unit_configuration_active == "No")
			if @project.present?
				uc.send("city=", @project.city.titleize.strip) if @project.city.present?
				uc.send("possession=", Time.parse(@project.possession.to_s)) if @project.possession.present?
				if @project.approved_banks.present?
					if @project.approved_banks.is_a?(String)
						uc.send("approved_banks=", @project.approved_banks.collect{|a|a.upcase})
					else
						uc.send("approved_banks=", @project.approved_banks.collect{|a|a.map(&:upcase)})
					end
				end
				uc.send("approval=", @project.approval)
				uc.send("launched_on=", Time.parse(@project.launched_on.to_s)) if @project.launched_on.present?
				uc.send("tag=", @project.suitable_for) if @project.suitable_for == "investors"

				# new fields from project added to UC
				uc.send("segment=", @project.project_segment)
				uc.send("project_size=", @project.project_size)
				uc.send("apartment_size=", @project.apartment_size.titleize) if @project.apartment_size.present?
				uc.send("zone=", @project.zone)
				uc.send("locality=", (@project.locality.gsub(/pune|bengaluru/i, "").strip rescue @project.locality))
				uc.send("administration=", @project.administration)
				uc.send("project_status=", @project.project_status)
				project_status_order = PROJECT_STATUS_ORDER.index(@project.project_status)
				uc.send("project_status_order=", project_status_order + 1) if project_status_order.present?
				uc.promoted = true if @project.promoted == "yes"
				uc.send("secondary_developer_ids=", @project.secondary_developer_ids)
				uc.send("secondary_developer_names=", @project.secondary_developer_names)
			else
				if @project.present?
					uc.unit_configuration_active = "No"
					parent_error+= "Active UC found for inactive Project. UC deactivated."
				else
					parent_error+= "Project for UC not found."
				end
			end
		end
		if uc.save
			if @project.present?
				@project.compute_area_price
				@project.save
			end
			render :json => {"status" => "Unit Configuration saved successfully. #{parent_error}"}, status: 200
		else
			render :json => {"status" => "Error in saving Unit Configuration details. #{parent_error}", "errors" =>  uc.errors.full_messages}, status: 500
		end

	end

	private
	def check_client_id
		if params[:project].present?
			@obj = JSON(params[:project])
		elsif params[:uc].present?
			@obj = JSON(params[:uc])
		elsif params[:project_unit].present?
			@obj = JSON(params[:project_unit])
		elsif params[:project_tower].present?
			@obj = JSON(params[:project_tower])
		#if Project.project_arr
			#@obj=Project.project_arr
		# elsif UnitConfiguration.unitlist.present?
		# 	@obj =  UnitConfiguration.unitlist
		# elsif ProjectUnit.get_unit_data.present?
		 	#@obj =  ProjectUnit.get_unit_data
		# elsif ProjectTower.towerlist.present?
			#@obj = ProjectTower.towerlist
		else
			render :json => {"status" => "Error: params not present", "errors" =>  ["Project params not present"]}, status: 500
			return
		end
		if @obj.present?
			if @obj["client_id"].to_s == CLIENT_ID
				if @obj["project_id"].present?
					@project = Project.unscoped.find(@obj["project_id"]) rescue nil
				end
			else
				render :json => {"status" => "Error: Client Id does not match", "errors" =>  ["Client Id does not match"]}, status: 500
				return
			end
		end
	end
end
