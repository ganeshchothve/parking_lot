module ApplicationConcern
  extend ActiveSupport::Concern

  def selected_account(klass, project_unit = nil)
    project_unit.try(:phase).try(:account) || Object.const_get("Account::#{klass.classify}Payment").where(by_default: true).first
  end
end
