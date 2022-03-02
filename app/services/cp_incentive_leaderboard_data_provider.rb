module CpIncentiveLeaderboardDataProvider
  def self.top_channel_partners
    vis_data = VariableIncentiveSchemeCalculator.vis_details
    manager_wise_total_incentive_data = []

    if vis_data.present?
      data_group_by_manager = vis_data.group_by{|data| data[:manager_id] }
      data_group_by_manager.each do |key, value|
        hash = {}
        hash[:manager_id] = key
        hash[:total_capped_incentive] = value.pluck(:capped_incentive).sum
        manager_wise_total_incentive_data << hash
      end
      incentives = manager_wise_total_incentive_data.pluck(:total_capped_incentive)
      ranks = calculate_ranks(incentives)
      manager_wise_total_incentive_data.each_with_index do |data, index|
        data.merge!(rank: ranks[index])
      end
    end

    manager_wise_total_incentive_data.sort_by!{|d| d[:rank] }
  end


  def self.calculate_ranks(arr)
    sorted = arr.sort.uniq.reverse
    ranks = arr.map{|e| sorted.index(e) + 1}
    ranks
  end
end