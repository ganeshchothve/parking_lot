class Admin::WorkflowPolicy < WorkflowPolicy
  def index?
    %w[superadmin admin sales].include?(user.role)
  end

  def create?
    index?
  end

  def update?
    create?
  end

  def permitted_attributes(params = {})
    attributes = []
    attributes += [:stage, pipelines_attributes: PipelinePolicy.new(user, Pipeline.new).permitted_attributes]
    attributes.uniq
  end
end
