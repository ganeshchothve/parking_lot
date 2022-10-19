class Admin::WorkflowPolicy < WorkflowPolicy
  def index?
    %w[superadmin admin].include?(user.role)
  end

  def create?
    %w[superadmin admin].include?(user.role)
  end

  def update?
    %w[superadmin admin].include?(user.role)
  end

  def permitted_attributes(params = {})
    attributes = []
    attributes += [:stage, :create_product, :deactivate_product, :update_product_on_deal , pipelines_attributes: PipelinePolicy.new(user, Pipeline.new).permitted_attributes]
    attributes.uniq
  end
end
