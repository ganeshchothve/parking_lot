class Search
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include ApplicationHelper

  field :bedrooms, type: Float
  field :carpet, type: String
  field :agreement_price, type: String
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
    params[:carpet] = carpet if carpet.present?
    params[:agreement_price] = agreement_price if agreement_price.present?
    params
  end

  def project_tower
    project_tower_id.present? ? ProjectTower.find(project_tower_id) : nil
  end

  def agreement_price_to_s
    if self.agreement_price.present?
      min_agreement_price = self.agreement_price.split("-")[0]
      max_agreement_price = self.agreement_price.split("-")[1]
      min_agreement_price_to_s = number_to_indian_currency(min_agreement_price)
      max_agreement_price_to_s = number_to_indian_currency(max_agreement_price)

      if min_agreement_price.present? && max_agreement_price.present?
        return "From #{min_agreement_price_to_s} to #{max_agreement_price_to_s}".html_safe
      elsif min_agreement_price.present? && max_agreement_price.blank?
        return "Starting #{min_agreement_price_to_s}".html_safe
      elsif min_agreement_price.blank? && max_agreement_price.present?
        return "Below #{min_agreement_price_to_s}".html_safe
      end
    else
      return ""
    end
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

  def crossed_step(st)
    current_index = allowed_steps.index(step)
    index = allowed_steps.index(st)
    current_index > index
  end
end
