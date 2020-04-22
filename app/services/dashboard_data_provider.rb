module DashboardDataProvider
  # TODO remove not used methods from old methods
  # old methods
  def self.channel_partners_dashboard(user, options={})
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

  def self.users_dashboard(user, options={})
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

  def self.user_requests_dashboard(user, options={})
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

  # new (according to new ui)
  def self.available_inventory
    ProjectUnit.where(status: 'available').count
  end

  def self.minimum_agreement_price
    ProjectUnit.gt(all_inclusive_price: 0).distinct(:all_inclusive_price).min
  end

  def self.configurations
    ProjectUnit.distinct(:unit_configuration_name).sample(3)
  end

  def self.total_buyers(current_user)
    User.where(role: { "$in": User::BUYER_ROLES}, manager_id: current_user.id).count
  end

  def self.user_group_by(current_user)
    out = {'confirmed_users': 0, 'not_confirmed_users': 0}
    data = User.collection.aggregate([
      {"$match": {'manager_id': current_user.id } },
      { "$group": {
        "_id":{
          "$cond": {if: '$confirmed_at', then: 'confirmed_users', else: 'not_confirmed_users'}
        },
        count: {
          "$sum": 1
        }
      }
    }]).to_a
    data.each do |d|
      out[(d['_id']).to_sym] = d['count']
    end
    out
  end

  def self.booking_detail_group_by(current_user)
    out = {'blocked': 0, 'booked_tentative': 0,'booked_confirmed': 0}
    user_ids = User.where(manager_id: current_user.id).pluck(:id)
    data = BookingDetail.collection.aggregate([
      {"$match": {'user_id': {'$in': user_ids }, 'status': {'$in': %w(blocked booked_confirmed booked_tentative)}} },
      { "$group": {
        "_id":{
          "status": "$status"
        },
        count: {
          "$sum": 1
        }
      }
    }]).to_a
    data.each do |d|
      out[(d['_id']['status']).to_sym] = d['count']
    end
    out
  end

  def self.receipts_group_by(current_user)
    out = {'pending': 0, 'clearance_pending': 0, 'success': 0, 'refunded': 0}
    user_ids = User.where(manager_id: current_user.id).pluck(:id)
    data = Receipt.collection.aggregate([
      {"$match": {'user_id': {'$in': user_ids }, 'status': {'$in': %w(pending clearance_pending success refunded)}} },
      { "$group": {
        "_id":{
          "status": "$status"
        },
        count: {
          "$sum": 1
        }
      }
    }]).to_a
    data.each do |d|
      out[(d['_id']['status']).to_sym] = d['count']
    end
    out
  end

  # Below method creates an inventory snapshot for dashboard
  # first $group groups on the basis project_tower_name and unit_configuration_name and calculates following for each group
  # 1. Count of project units in blocked status
  # 2. Count of project units in available, management blocking an employee status
  # 3. Sum of agreement_price of blocked units
  # 4. Ids of blocked units for collection calculation
  # 5. Total number of units
  # second $group on the basis of project_tower_name and caculates the following
  # 1. Total blocked units of the tower
  # 2. Total available units of the tower
  # 3. Total Units of the tower
  # 4. Total agreement price of the tower
  # 5. Total blocked unit ids in the system
  # 6. Push configuration wise data (sold and unsold unit count) calculated in first group query

  def self.inventory_snapshot
    grouping = {
      project_tower_name: "$project_tower_name",
      unit_configuration_name: "$unit_configuration_name"
    }
    data = ProjectUnit.collection.aggregate([{
          "$group":
          {
            "_id": grouping,
            blocked:{ "$sum": { "$cond": [ {"$eq": ['$status', {"$literal": 'blocked'}]}, 1, 0 ] } },
            agreement_price: { "$sum": { "$cond": [ {"$eq": ['$status', {"$literal": 'blocked'}]}, "$agreement_price", 0 ] } },
            available: { "$sum": { "$cond": [ {"$in": ['$status', ['available', "management_blocking", "employee"]]}, 1, 0 ] } },
            blocked_project_units:{ "$push": { "$cond": [ {"$eq": ['$status', {"$literal": 'blocked'}]}, "$_id", nil] } },
            total: { "$sum": 1 }
          }
        },{
          "$group":
          {
            "_id": "$_id.project_tower_name",
            total_blocked: { "$sum": "$blocked" },
            total_available: { "$sum": "$available" },
            total: { "$sum": "$total"},
            total_agreement_price: { "$sum": "$agreement_price" },
            total_blocked_project_units: { "$push": "$blocked_project_units" },
            configuration_wise: { "$push": { unit_configuration_name: "$_id.unit_configuration_name", available: "$available", blocked: "$blocked" }}
          }
        }]).to_a
    out = {}
    out["All Towers"] = {total: 0, sold: 0, unsold: 0, av_sold: 0, collection: 0}
    out["All Towers"][:configuration_wise] = new_unit_configuration_hash
    data.each do |_data|
      out[_data["_id"]] = {total: _data["total"], sold: _data["total_blocked"], unsold: _data["total_available"], av_sold: _data["total_agreement_price"]}
      _unit_configuration_hash = new_unit_configuration_hash
      _data["configuration_wise"].each do |uc|
        _unit_configuration_hash[uc["unit_configuration_name"]] = {sold: uc["blocked"], unsold: uc["available"]}

      end
      out[_data["_id"]][:configuration_wise] = _unit_configuration_hash
      _blocked_units = _data["total_blocked_project_units"].flatten.compact.map{|id| id.to_s}
      _booking_detail_ids = BookingDetail.where(status: {"$in": BookingDetail::BOOKING_STAGES}, project_unit_id: {"$in": _blocked_units}).pluck(:id)
      out[_data["_id"]][:collection] = Receipt.in(booking_detail_id: _booking_detail_ids).in(status:["success","clearance_pending"]).sum(:total_amount)
      out["All Towers"] = calculate_all_towers(out["All Towers"], out[_data["_id"]])
    end
    out
  end

  protected

  def self.calculate_all_towers all_towers_out, current_tower_data
    all_towers_out[:total] += current_tower_data[:total]
    all_towers_out[:sold] += current_tower_data[:sold]
    all_towers_out[:unsold] += current_tower_data[:unsold]
    all_towers_out[:av_sold] += current_tower_data[:av_sold]
    all_towers_out[:collection] += current_tower_data[:collection]
    ProjectUnit.distinct(:unit_configuration_name).sort.each do |uc|
      all_towers_out[:configuration_wise][uc][:sold] += current_tower_data[:configuration_wise][uc][:sold]
      all_towers_out[:configuration_wise][uc][:unsold] += current_tower_data[:configuration_wise][uc][:unsold]
    end
    all_towers_out
  end

  def self.new_unit_configuration_hash
    _unit_configuration_hash = {}
    ProjectUnit.distinct(:unit_configuration_name).sort.each do |uc|
      _unit_configuration_hash[uc] = {sold: 0, unsold: 0}
    end
    _unit_configuration_hash
  end

  def get_matcher
    # GENERICTODO
  end

end
