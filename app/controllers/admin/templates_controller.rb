class Admin::TemplatesController < AdminController
  before_action :set_template, except: [:index]
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
    if params[:action] == "index"
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
