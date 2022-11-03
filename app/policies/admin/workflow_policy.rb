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

  def can_create_product?
    record.can_create_product?
  end

  def can_deactivate_product?
    record.can_deactivate_product?
  end

  def can_update_product_on_deal?
    record.can_update_product_on_deal?
  end

  def permitted_attributes(params = {})
    attributes = []
    attributes += [:stage, :create_product, :deactivate_product, :update_product_on_deal , pipelines_attributes: PipelinePolicy.new(user, Pipeline.new).permitted_attributes]
    attributes.uniq
  end
end
