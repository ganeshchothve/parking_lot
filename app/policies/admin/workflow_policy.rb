class Admin::WorkflowPolicy < WorkflowPolicy
  def index?
    if current_client.real_estate?
      %w[superadmin admin].include?(user.role)
    else
      false
    end
  end

  def create?
    %w[superadmin admin].include?(user.role)
  end

  def update?
    record.is_active? && %w[superadmin admin].include?(user.role)
  end

  def edit?
    index?
  end

  def pipeline_stages?
    index?
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

  def can_set_product_amount_type?
    record.can_set_product_amount_type?
  end

  def enable_disable_workflow?
    %w[superadmin admin].include?(user.role)
  end

  def destroy?
    !record.is_active? && edit?
  end

  def permitted_attributes(params = {})
    attributes = []
    attributes += [:stage, :create_product, :deactivate_product, :update_product_on_deal, :product_amount_type, :is_active, pipelines_attributes: PipelinePolicy.new(user, Pipeline.new).permitted_attributes]
    attributes.uniq
  end
end
