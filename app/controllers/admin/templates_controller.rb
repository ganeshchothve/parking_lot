class Admin::TemplatesController < AdminController
  before_action :set_template, except: [:index, :new, :create]
  before_action :authorize_resource
  around_action :apply_policy_scope, only: [:index]

  layout :set_layout

  def index
    @templates = Template.build_criteria params
    @templates = @templates.paginate(page: params[:page] || 1, per_page: params[:per_page])
    respond_to do |format|
      format.json { render json: @templates }
      format.html {}
    end
  end

  def new
    @template = Template::CustomTemplate.new(booking_portal_client_id: (current_user.selected_client_id || current_client.id))
    render layout: false
  end

  def create
    @template = Template::CustomTemplate.new(booking_portal_client_id: (current_user.selected_client_id || current_client.id))
    @template.assign_attributes(permitted_attributes([:admin, @template]))
    respond_to do |format|
      if @template.save
        format.html { redirect_to admin_incentive_schemes_path, notice: 'Template created successfully.' }
        format.json { render json: @template, status: :created }
      else
        format.html { render :new }
        format.json { render json: { errors: @template.errors.full_messages.uniq }, status: :unprocessable_entity }
      end
    end
  end

  def edit
    render layout: false
  end

  def update
    @template.assign_attributes(permitted_attributes([:admin, @template]))
    _params = Rack::Utils.parse_nested_query(URI(request.referrer).query)
    respond_to do |format|
      if @template.save
        format.html { redirect_to admin_client_templates_path, notice: 'Template was successfully updated.' }
        format.json { render json: @template, location: admin_client_templates_path(fltrs: _params['fltrs'] || {}, page: _params['page'] || 1) }
      else
        format.html { render :edit }
        format.json { render json: {errors: @template.errors.full_messages.uniq}, status: :unprocessable_entity }
      end
    end
  end

  private
  def set_template
    @template = ::Template.find(params[:id])
  end

  def authorize_resource
    if %w(index new create).include?(params[:action])
      authorize [:admin, ::Template]
    else
      authorize [:admin, @template]
    end
  end

  def apply_policy_scope
    custom_scope = Template.criteria
    Template.with_scope(policy_scope(custom_scope)) do
      yield
    end
  end
end
