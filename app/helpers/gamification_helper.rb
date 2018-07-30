module GamificationHelper
  def booked_homes_count
    ProjectUnit.build_criteria({
      fltrs: {
        status: ["blocked", "booked_tentative", "booked_confirmed"]
      }
    }).count + 116
  end

  def booked_today_count
    BookingDetail.where(created_at: {"$gte" => Time.now.in_time_zone("Mumbai").beginning_of_day}).count + 6
  end

  def bhk_booked(bedrooms)
    ProjectUnit.build_criteria({
      fltrs: {
        status: ["blocked", "booked_tentative", "booked_confirmed"],
        bedrooms: bedrooms
      }
    }).count + 30
  end

  def units_booked_by_towers
    counts = ProjectUnit.collection.aggregate([{
      "$match": {
        status: {
          "$in": ["blocked", "booked_tentative", "booked_confirmed"]
        }
      }
    },{
      "$group": {
        "_id": {
          project_tower_id: "$project_tower_id"
        },
        count: {
          "$sum": 1
        }
      }
    }]).to_a
    counts.each do |x|
      x["count"] = x["count"] + 116/6
    end
  end
end
