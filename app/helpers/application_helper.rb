module ApplicationHelper
  def global_labels
    t('global').with_indifferent_access
  end
end
