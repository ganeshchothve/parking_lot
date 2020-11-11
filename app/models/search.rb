class Search
  include Mongoid::Document
  include Mongoid::Timestamps
  include ArrayBlankRejectable
  include ApplicationHelper

  field :bedrooms, type: Float
  field :carpet, type: String
  field :agreement_price, type: String
  field :all_inclusive_price, type: String
  field :floor, type: Integer
  field :step, type: String, default: "filter"
  field :results_count, type: Integer
  # field :result_ids, type: Array

  belongs_to :lead
  belongs_to :user, optional: true
  belongs_to :project_unit, optional: true
  belongs_to :project_tower, optional: true

  delegate :manager_id, to: :user, prefix: true, allow_nil: true

  def params_json
    params = {}
    params[:bedrooms] = bedrooms if bedrooms.present?
    params[:carpet] = carpet if carpet.present?
    params[:agreement_price] = agreement_price if agreement_price.present?
    params[:all_inclusive_price] = all_inclusive_price if all_inclusive_price.present?
    params
  end

  def range_string price
    if price.present?
      min_price = price.split("-")[0]
      max_price = price.split("-")[1]
      min_price_to_s = number_to_indian_currency(min_price)
      max_price_to_s = number_to_indian_currency(max_price)

      if min_price.present? && max_price.present?
        return "From #{min_price_to_s} to #{max_price_to_s}".html_safe
      elsif min_price.present? && max_price.blank?
        return "Starting #{min_price_to_s}".html_safe
      elsif min_price.blank? && max_price.present?
        return "Below #{min_price_to_s}".html_safe
      end
    else
      return ""
    end
  end

  def all_inclusive_price_to_s
    range_string(all_inclusive_price)
  end

  def agreement_price_to_s
    range_string(agreement_price)
  end

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
