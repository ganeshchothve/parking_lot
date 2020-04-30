module RenderAnywhere
  def render_anywhere(partial, assigns = {}, layout = nil)
    view = ActionView::Base.new(ActionController::Base.view_paths, assigns)
    view.extend Pundit
    view.extend ApplicationHelper
    _attrs = { partial: partial }
    _attrs[:layout] = layout if layout
    view.render(_attrs)
  end
end
