class Search
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable

  field :bedrooms, type: Float
  field :carpet, type: Float
  field :agreement_price, type: Float
  field :project_tower_id, type: String
  field :floor, type: Integer
  field :project_unit_id, type: String
  field :step, type: String, default: "filter"
  field :results_count, type: Integer
  # field :result_ids, type: Array

  belongs_to :user

  def params_json
    params = {}
    params[:bedrooms] = bedrooms if bedrooms.present?
    if carpet.present?
      params[:carpet] = {}
      params[:carpet]["$gte"] = carpet.split("-")[0]
      params[:carpet]["$lte"] = carpet.split("-")[1]
    end
    if agreement_price.present?
      params[:agreement_price] = {}
      params[:agreement_price]["$gte"] = agreement_price.split("-")[0]
      params[:agreement_price]["$lte"] = agreement_price.split("-")[1]
    end
    params
  end
  # GENERIC_TODO SelldoLeadUpdater.perform_async(current_user.id.to_s, "unit_browsing")
  # GENERIC_TODO SelldoLeadUpdater.perform_async(current_user.id.to_s, "unit_selected")

  # GENERIC_TODO : remove a step from here to modify the flow
  def allowed_steps
    ["filter", "towers", "project_unit"]
  end

  def next_step
    index = allowed_steps.index(step)
    index < (allowed_steps.length - 1) ? allowed_steps[index + 1] : nil
  end

  def previous_step
    index = allowed_steps.index(step)
    index == 0 ? nil : allowed_steps[index - 1]
  end
end
