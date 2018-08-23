module DashboardDataProvider
  def self.channel_partners_dashboard(user)
    data = ChannelPartner.collection.aggregate([{
      "$group": {
        "_id": {
          status: "$status"
        },
        count: {
          "$sum": 1
        }
      }
    }]).to_a
    out = []
    data.each do |d|
      out << {status: d["_id"]["status"], count: d["count"]}.with_indifferent_access
    end
    out
  end

  def self.receipts_dashboard(user, matcher={})
    unless matcher.present? && matcher[:user_id].present?
      matcher = Receipt.user_based_scope(user)
    end
    data = Receipt.collection.aggregate([{
        "$match": matcher
      }, {
      "$group": {
        "_id": {
          payment_mode: "$payment_mode",
          status: "$status"
        },
        total_amount: {
          "$addToSet": "$total_amount"
        },
        count: {
          "$sum": 1
        }
      }
    },{
      "$sort": {
        "_id.status": 1
      }
    },{
      "$project": {
        total_amount: {"$sum": "$total_amount"},
        payment_mode: "$payment_mode",
        status: "$status",
        count: "$count"
      }
    }]).to_a
    out = []
    data.each do |d|
      out << {payment_mode: d["_id"]["payment_mode"], status: d["_id"]["status"], count: d["count"], total_amount: d["total_amount"]}.with_indifferent_access
    end
    out
  end

  def self.users_dashboard(user)
    data = User.collection.aggregate([{
        "$match": User.user_based_scope(user)
      },{
      "$group": {
        "_id": {
          role: "$role"
        },
        count: {
          "$sum": 1
        }
      }
    }]).to_a
    out = []
    data.each do |d|
      out << {role: d["_id"]["role"], count: d["count"]}.with_indifferent_access
    end
    out
  end

  def self.cancellation_user_requests_dashboard(user)
    out = []
    ["pending", "resolved"].each do |status|
      user_requests = UserRequest.where(request_type: "cancellation").where(status: status)
      unit_ids = user_requests.distinct(:project_unit_id)
      data = ProjectUnit.collection.aggregate([{
        "$match": {
          _id: {
            "$in": unit_ids
          }
        }
      }, {
        "$project": {
          total_agreement_price: "$agreement_price",
          total_all_inclusive_price: "$all_inclusive_price"
        }
      }]).to_a
      if data.length > 0
        out << {
          status: status,
          total_agreement_price: data.sum{|x| x["total_agreement_price"]},
          total_all_inclusive_price: data.sum{|x| x["total_all_inclusive_price"]},
          count: data.length
        }
      end
    end
    out
  end

  def self.project_units_dashboard(user)
    data = ProjectUnit.collection.aggregate([{
      "$group": {
        "_id": {
          status: "$status",
          bedrooms: "$bedrooms",
          project_tower_id: "$project_tower_id"
        },
        agreement_price: {
          "$addToSet": "$agreement_price"
        },
        all_inclusive_price: {
          "$addToSet": "$all_inclusive_price"
        },
        project_tower_name: {
          "$addToSet": "$project_tower_name"
        },
        count: {
          "$sum": 1
        }
      }
    },{
      "$sort": {
        "_id.bedrooms": 1
      }
    },{
      "$project": {
        total_agreement_price: {"$sum": "$agreement_price"},
        total_all_inclusive_price: {"$sum": "$all_inclusive_price"},
        bedrooms: "$bedrooms",
        project_tower_name: {"$arrayElemAt": ["$project_tower_name", 0]},
        status: "$status",
        count: "$count"
      }
    }]).to_a
    out = []
    data.each do |d|
      out << {bedrooms: d["_id"]["bedrooms"], project_tower_id: d["_id"]["project_tower_id"], project_tower_name: d["project_tower_name"], status: d["_id"]["status"], count: d["count"], total_all_inclusive_price: d["total_all_inclusive_price"], total_agreement_price: d["total_agreement_price"]}.with_indifferent_access
    end
    out
  end

  protected
  def get_matcher
    # GENERICTODO
  end
end
