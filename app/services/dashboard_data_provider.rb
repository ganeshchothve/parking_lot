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

  def self.receipts_available_group_by
    [
      {id: "status", text: "Status"},
      {id: "payment_mode", text: "Payment Mode"}
    ]
  end

  def self.receipts_dashboard(user, options={})
    options ||= {}
    matcher = options[:matcher]
    group_by = options[:group_by]
    unless matcher.present? && matcher[:user_id].present?
      matcher = Receipt.user_based_scope(user)
    end
    grouping = {
      payment_mode: "$payment_mode",
      status: "$status"
    }
    if group_by.present?
      grouping = {}
      grouping[:status] = "$status" if group_by.include?("status")
      grouping[:payment_mode] = "$payment_mode" if group_by.include?("payment_mode")
    end
    data = Receipt.collection.aggregate([{
        "$match": matcher
      }, {
      "$group": {
        "_id": grouping,
        total_amount: {"$sum": "$total_amount"},
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
        total_amount: "$total_amount",
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
    data = UserRequest.collection.aggregate([{
      "$group": {
        "_id":{
          "_type": "$_type",
          "status": "$status"
        },
        count: {
          "$sum": 1
        }
      }
    }]).to_a
    out = []
    data.each do |d|
      out << {_type: d["_id"]["_type"], status: d["_id"]["status"], count: d["count"]}.with_indifferent_access
    end
    out
  end

  def self.project_units_available_group_by
    [
      {id: "status", text: "Status"},
      {id: "bedrooms", text: "Bedrooms"},
      {id: "project_tower_id", text: "Project Tower"}
    ]
  end

  def self.project_units_dashboard(user, options={})
    options ||= {}
    grouping = {
      status: "$status",
      bedrooms: "$bedrooms",
      project_tower_id: "$project_tower_id"
    }
    if options[:group_by].present?
      grouping = {}
      grouping[:status] = "$status" if options[:group_by].include?("status")
      grouping[:bedrooms] = "$bedrooms" if options[:group_by].include?("bedrooms")
      grouping[:project_tower_id] = "$project_tower_id" if options[:group_by].include?("project_tower_id")
    end
    data = ProjectUnit.collection.aggregate([{
      "$group": {
        "_id": grouping,
        agreement_price: {"$sum": "$agreement_price"},
        all_inclusive_price: {"$sum": "$all_inclusive_price"},
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
        total_agreement_price: "$agreement_price",
        total_all_inclusive_price: "$all_inclusive_price",
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
