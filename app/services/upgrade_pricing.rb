class UpgradePricing
  def self.perform
    sold_count = ProjectUnit.in(status: ['blocked', 'booked_tentative', 'booked_confirmed']).count
    updated_rate = get_upgraded_base_rate(sold_count)
    current_max_rate = ProjectUnit.max(:base_rate)
    if updated_rate > current_max_rate
      ids = ProjectUnit.where(status: "available").distinct(:id)
      ProjectUnit.where(status: "available").update_all(base_rate: updated_rate)
      ApplicationLog.log("price_upgraded", {
        updated_rate: updated_rate,
        current_max_rate: current_max_rate,
        sold_count: sold_count,
        ids: ids.collect{|x| x.to_s}
      })
    end

  end

  def self.get_upgraded_base_rate sold_count=nil
    sold_count = ProjectUnit.in(status: ['blocked', 'booked_tentative', 'booked_confirmed']).count if sold_count.blank?
    new_rate = 4299
    if sold_count >= 100 && sold_count <= 199
      new_rate = 4349
    elsif sold_count >= 200 && sold_count <= 299
      new_rate = 4399
    elsif sold_count >= 300 && sold_count <= 399
      new_rate = 4449
    elsif sold_count >= 300 && sold_count <= 399
      new_rate = 4524
    elsif sold_count >= 520 && sold_count <= 639
      new_rate = 4624
    elsif sold_count >= 640
      new_rate = 4744
    end
    new_rate
  end
end
