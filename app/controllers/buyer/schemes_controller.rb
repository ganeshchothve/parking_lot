class Buyer::SchemesController < BuyerController
  include SchemesConcern

  before_action :set_project
  before_action :authorize_resource
  around_action :apply_policy_scope
end
