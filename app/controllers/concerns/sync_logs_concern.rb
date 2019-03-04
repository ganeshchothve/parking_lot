module SyncLogsConcern
  include Api
  extend ActiveSupport::Concern

  private

  def apply_policy_scope
    SyncLog.with_scope(policy_scope(SyncLog.criteria)) do
      yield
    end
   end
end
