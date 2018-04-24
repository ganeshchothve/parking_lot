class UpgradePricing
  def self.perform
    ProjectUnit.where(status: "available").update_all(base_rate: get_upgraded_base_rate)
  end

  def self.get_upgraded_base_rate
    sold_count = ProjectUnit.in(status: ['blocked', 'booked_tentative', 'booked_confirmed']).count
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
