module DashboardDataProvider
  # TODO remove not used methods from old methods
  # old methods

  def self.city_wise_booking_report (current_user, matcher={})
    city_wise_booking_count = {}
    data = BookingDetail.collection.aggregate([
      {
        '$match': matcher.merge(BookingDetail.user_based_scope(current_user))
      },
      {
        "$project": {
          "name": "$name",
          "project_id": "$project_id"
        }
      },
      {
        '$group': {
          '_id': '$project_id',
          'bookings_count': { '$sum': 1}
        }
      },
      {
          '$lookup': {
          'from': "projects",
          'let': { 'id': "$_id" },
          'pipeline': [
            { '$match': { '$expr': { '$eq': [ "$_id",  "$$id" ] } } },
            { '$project': { 'city': '$city' } }
          ],
          'as': "projects"
        }
      },
      {
        '$replaceRoot': {
          'newRoot': {
            '$mergeObjects': [
              { '$arrayElemAt': [ "$projects", 0 ] },
              "$$ROOT"
            ]
          }
        }
      }
    ]).as_json
    data.each do |d|
      if city_wise_booking_count[d['city']].present?
        city_wise_booking_count[d['city']].push({ project_id: d['_id'], bookings_count: d['bookings_count'] })
      else
        city_wise_booking_count[d['city']] = [{ project_id: d['_id'], bookings_count: d['bookings_count'] }]
      end
    end
    city_wise_booking_count
  end

  def self.incetive_scheme_max_ladders(current_user, options)
    matcher = {}
    matcher = options[:matcher] if options[:matcher].present?
    data = IncentiveScheme.collection.aggregate([{
            "$match": matcher.merge(IncentiveScheme.user_based_scope(current_user))
          },{
            "$unwind": "$ladders"
          },{
            "$group":
            {
              "_id": "$id",
              max: {"$max": "$ladders.stage"}
            }
          }]).to_a
    data.dig(0, "max") || 0
  end

  def self.project_wise_booking_details_data(current_user, matcher = {})
    matcher = matcher.with_indifferent_access
    project_ids = matcher[:project_id][:$in].map(&:to_s)
    booking_stages = ["blocked", "under_negotiation", "booked_tentative", "booked_confirmed", "cancelled"]
    data = BookingDetail.collection.aggregate([
      {"$match": matcher.merge(BookingDetail.user_based_scope(current_user))},
      {
        "$group": {
          "_id": {
            "booking_status": "$status",
            "project_id": "$project_id"
          },
          "count": {"$sum": 1}
        }
      }
    ]).as_json
    booking_data = []
    project_ids.each do |project_id|
      booking_data << {project_id: project_id, blocked: 0, under_negotiation: 0, booked_tentative: 0, booked_confirmed: 0, cancelled: 0}
    end
    booking_data.each do |booking_d|
      data.each do |d|
        d = d.with_indifferent_access
        if booking_d[:project_id] == d[:_id][:project_id]
          booking_d[:"#{d[:_id][:booking_status]}"] = d[:count]
        end
      end
    end
    booking_data
  end

  def self.project_wise_conversion_report_data(current_user, matcher = {})
    matcher = matcher.with_indifferent_access
    project_ids = matcher[:project_id][:$in]

    leads = Lead.where(matcher).group_by{|p| p.project_id}
    all_site_visits = SiteVisit.where(matcher)
    site_visits = all_site_visits.group_by{|p| p.project_id}
    revisits = all_site_visits.where(is_revisit: true).group_by{|p| p.project_id}

    all_bookings = BookingDetail.where(matcher)
    bookings = all_bookings.group_by{|p| p.project_id}
    registered_bookings = all_bookings.where(registration_done: true).group_by{|p| p.project_id}
    token_payments = Receipt.where(matcher).where(payment_type: 'token').group_by{|p| p.project_id}

    conversion_data = []
    total_bookings_count, total_token_payment_count = 0, 0
    project_ids.each do |project_id|
      bookings_count = bookings[project_id].try(:count) || 0
      token_payment_count = token_payments[project_id].try(:count) || 0
      total_bookings_count += bookings_count
      total_token_payment_count += token_payment_count
      token_payments_to_bookings_ratio = ( (token_payment_count / bookings_count.to_f) * 100 ).round rescue '0'
      conversion_data << {project_id: project_id, leads: leads[project_id].try(:count) || 0, site_visits: site_visits[project_id].try(:count) || 0, revisits: revisits[project_id].try(:count) || 0, token_payments: token_payment_count, bookings: bookings_count, registered_bookings: registered_bookings[project_id].try(:count) || 0, conversion_ratio: ( '<b>' + token_payments_to_bookings_ratio.to_s + ' %</b>').html_safe }
    end
    avg_token_payments_to_bookings_ratio = ( (total_token_payment_count / total_bookings_count.to_f) * 100 ).round rescue '0'
    return [conversion_data, avg_token_payments_to_bookings_ratio]
  end

  def self.cp_performance_walkins(user, options={})
    matcher = {}
    matcher = options[:matcher] if options[:matcher].present?
    matcher.merge!(Lead.user_based_scope(user))
    data = Lead.collection.aggregate([{
            "$match": matcher
          },{
            "$project":
            {
              "lead_id": "$id",
              "cp_id": "$cp_manager_id"
            }
          },{
            "$group":
            {
              "_id": "$cp_id",
              "count": {"$sum": 1}
            }
          }]).to_a
    out = {}
    data.each do |d|
      out[d["_id"]] = d["count"]
    end
    out
  end

  def self.cp_performance_site_visits(user, options={})
    matcher = {}
    matcher = options[:matcher] if options[:matcher].present?
    matcher.merge!(SiteVisit.user_based_scope(user))
    data = SiteVisit.collection.aggregate([{
            "$match": matcher
          },{
            "$lookup":
            {
              "from": "users",
              "localField": "manager_id",
              "foreignField": "_id",
              "as": "manager"
            }
          },{
            "$project":
            {
              "sv_id": "$id",
              "cp_id": "$manager.manager_id",
              'approval_status': '$approval_status',
              'status': '$status'
            }
          },{
            "$group":
            {
              "_id": {cp_id: "$cp_id", 'status': '$status', 'approval_status': '$approval_status'},
              "count": {"$sum": 1}
            }
          }]).to_a
    out = {'pending' => {}, 'approved' => {}, 'rejected' => {}, 'scheduled' => {}, 'conducted' => {}}
    data.each do |d|
      status = d.dig('_id', 'status')
      approval_status = d.dig('_id', 'approval_status')
      cp = d.dig('_id', 'cp_id')&.first&.to_s&.presence || nil
      if status.present? && %w(scheduled conducted).include?(status) && cp.present?
        out[status][cp] ||= 0
        out[status][cp] += d["count"]
      end
      if approval_status.present? && cp.present?
        out[approval_status][cp] ||= 0
        out[approval_status][cp] += d["count"]
      end
    end
    out
  end

  def self.cp_performance_bookings(user, options={})
    matcher = {}
    matcher = options[:matcher] if options[:matcher].present?
    matcher.merge!(BookingDetail.where(BookingDetail.user_based_scope(user)).booking_stages.selector)
    data = BookingDetail.collection.aggregate([{
            "$match": matcher
          },{
            "$lookup":
            {
              "from": "users",
              "localField": "manager_id",
              "foreignField": "_id",
              "as": "manager"
            }
          },{
            "$project":
            {
              "lead_id": "$lead_id",
              "cp_id": "$manager.manager_id",
              "agreement_price": "$agreement_price"
            }
          },{
            "$group":
            {
              "_id": "$cp_id",
              "count": {"$sum": 1},
              "sales_revenue": {"$sum": "$agreement_price"}
            }
          }]).to_a
    out = {}
    data.each do |d|
      out[d["_id"].first] = {count: d["count"], sales_revenue: d["sales_revenue"]}
    end
    out
  end

  def self.inventive_scheme_performance(user, options = {})
    matcher = {}
    matcher = options[:matcher] if options[:matcher].present?
    matcher.merge!(Invoice.user_based_scope(user))
    data = Invoice.collection.aggregate([{
            "$match": matcher
          }, {
          "$group": {
            "_id": {
              "ladder_id": "$ladder_id",
              "manager_id": "$manager_id"
            }
          }
        },{
          "$group": {
            "_id": "$_id.ladder_id",
            "count": {"$sum": 1}
          }

        }]).to_a
    out = {}
    data.each do |d|
      out[d["_id"]] = d["count"]
    end
    out
  end

  def self.channel_partners_dashboard(user, options={})
    data = ChannelPartner.collection.aggregate([
      {"$match": matcher.merge(ChannelPartner.user_based_scope(user))},
      {
        "$group": {
          "_id": {
            status: "$status"
          },
          count: {
            "$sum": 1
          }
        }
      }
    ]).to_a
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

  def self.receipt_details_data(user, options={})
    options = options.with_indifferent_access
    group_by = options[:group_by]
    matcher = options[:matcher] || {}
    matcher = matcher.with_indifferent_access
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
        "$match": matcher.merge(Receipt.user_based_scope(user))
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

  def self.project_wise_user_requests_report_data(user, options={})
    matcher = options[:matcher] || {}
    matcher = matcher.with_indifferent_access
    data = UserRequest.collection.aggregate([
      { "$match": matcher },
      {
        "$group": {
          "_id":{
            "project_id": "$project_id",
            "_type": "$_type"
          },
          "statuses": { "$push": "$status" }
        }
      }
    ]).to_a
    out = []
    data.each do |d|
      out << {project_id: d["_id"]["project_id"], _type: d["_id"]["_type"], status: { pending: d["statuses"].count("pending") || 0, resolved: d["statuses"].count("resolved") || 0, rejected: d["statuses"].count("rejected") || 0 } }.with_indifferent_access
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

  def self.project_units_inventory_report_data(user, options={})
    options ||= {}
    options = options.with_indifferent_access
    matcher = options[:matcher] || {}
    matcher = matcher.with_indifferent_access
    grouping = {
      status: "$status",
      bedrooms: "$bedrooms",
      project_tower_id: "$project_tower_id",
      project_id: "$project_id"
    }
    if options[:group_by].present?
      grouping = {project_id: "$project_id"}
      grouping[:status] = "$status" if options[:group_by].include?("status")
      grouping[:bedrooms] = "$bedrooms" if options[:group_by].include?("bedrooms")
      grouping[:project_tower_id] = "$project_tower_id" if options[:group_by].include?("project_tower_id")
    end
    data = ProjectUnit.collection.aggregate([
      { "$match": ProjectUnit.user_based_scope(user)},
      { "$match": matcher },
      {
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
      },
      {
        "$sort": {
          "_id.bedrooms": 1
        }
      },
      {
        '$lookup': {
          from: "projects",
          let: { project_id: "$_id.project_id" },
          pipeline: [
            { '$match': { '$expr': { '$eq': [ "$_id",  "$$project_id" ] } } },
            { '$project': { project_name: '$name' } }
          ],
          as: "project"
        }
      },
        {
        "$project": {
          total_agreement_price: "$agreement_price",
          total_all_inclusive_price: "$all_inclusive_price",
          bedrooms: "$bedrooms",
          project_tower_name: {"$arrayElemAt": ["$project_tower_name", 0]},
          project_name: {"$arrayElemAt": ["$project.project_name", 0]},
          status: "$status",
          count: "$count"
        }
      },
      {
        "$sort": {
          "project_name": 1
        }
      }
    ]).to_a
    out = []
    data.each do |d|
      out << {bedrooms: d["_id"]["bedrooms"], project_tower_id: d["_id"]["project_tower_id"], project_tower_name: d["project_tower_name"], status: d["_id"]["status"], count: d["count"], total_all_inclusive_price: d["total_all_inclusive_price"], total_agreement_price: d["total_agreement_price"], project_id: d["_id"]["project_id"], project_name: d["project_name"]}.with_indifferent_access
    end
    out
  end

  # new (according to new ui)
  def self.available_inventory(user, project = nil)
    if project.present?
      project.project_units.where(ProjectUnit.user_based_scope(user)).where(status: 'available').count
    else  
      ProjectUnit.where(ProjectUnit.user_based_scope(user)).where(status: 'available').count
    end
  end

  def self.minimum_agreement_price(user, project = nil)
    if user.present?
      if project.present?
        project.project_units.where(ProjectUnit.user_based_scope(user)).gt(all_inclusive_price: 0).distinct(:all_inclusive_price).min
      else
        ProjectUnit.where(ProjectUnit.user_based_scope(user)).gt(all_inclusive_price: 0).distinct(:all_inclusive_price).min
      end
    end
  end

  def self.configurations(user, project = nil)
    if project.present?
      project.unit_configurations.where(UnitConfiguration.user_based_scope(user)).collect(&:name)&.uniq&.sample(3)
    else
      UnitConfiguration.where(UnitConfiguration.user_based_scope(user)).all.collect(&:name)&.uniq&.sample(3)
    end
  end

  def self.total_buyers(current_user, params={})
    Lead.where(Lead.user_based_scope(current_user)).build_criteria(params).count
  end

  def self.incentive_pending_bookings(current_user, filters={})
    booking_ids = Invoice.where(Invoice.user_based_scope(user)).where(manager_id: current_user.id).distinct(:booking_detail_id)
    BookingDetail.where(BookingDetail.user_based_scope(user)).booking_stages.where(manager_id: current_user.id).build_criteria(filters).nin(id: booking_ids).count
  end

  def self.lead_group_by(current_user, options={})
    matcher = Lead.where(Lead.user_based_scope(current_user)).selector
    matcher = matcher.merge!(options[:matcher]) if options[:matcher].present?
    data = Lead.collection.aggregate([
      {"$match": matcher},
      {'$lookup': {
          from: "booking_details",
          localField: "_id",
          foreignField: "lead_id",
          as: "booking_details"
        }
      },
      { "$group": {
        "_id":{
          "$cond": {if: {'$gte': [{'$size': '$booking_details'}, 1]}, then: 'booked', else: 'not_booked'}
        },
        count: {
          "$sum": 1
        }
      }}
    ]).to_a
    data.inject({}) { |hsh, d| hsh[d['_id']] = d['count']; hsh }
  end

  def self.booking_detail_group_by(current_user, options={})
    out = {'blocked': 0, 'booked_tentative': 0,'booked_confirmed': 0}
    matcher = {manager_id: current_user.id, 'status': {'$in': %w(blocked booked_confirmed booked_tentative)}}
    matcher = matcher.merge!(options[:matcher]) if options[:matcher].present?
    data = BookingDetail.collection.aggregate([
      {"$match":  matcher.merge(BookingDetail.user_based_scope(current_user))},
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

  def self.receipts_group_by(current_user, options)
    out = {'pending': 0, 'clearance_pending': 0, 'success': 0, 'refunded': 0}
    lead_ids = Lead.where(Lead.user_based_scope(current_user)).where(manager_id: current_user.id).pluck(:id)
    matcher = {'lead_id': {'$in': lead_ids }, 'status': {'$in': %w(pending clearance_pending success refunded)}}
    matcher = matcher.merge!(options[:matcher]) if options[:matcher].present?
    data = Receipt.collection.aggregate([
      {"$match":  matcher.merge(Receipt.user_based_scope(current_user))},
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

  def self.project_wise_leads_count(current_user, options={})
    matcher = { manager_id: current_user.id }
    matcher = matcher.merge!(options[:matcher]) if options[:matcher].present?
    data = Lead.collection.aggregate([
      {'$match': matcher.merge(Lead.user_based_scope(current_user))},
      {'$group': {
        _id: '$project_id',
        count: {
          '$sum': 1
        }
      } },
      {'$group': {
        _id: nil,
        total_count: { '$sum': '$count' },
        project_wise: { '$push': {'project_id': '$_id', count: '$count'} }
      } }
    ]).to_a
    data = data.first
    data['project_wise'] = data['project_wise'].inject({}) {|hsh, x| hsh[x['project_id']] = x.except('project_id'); hsh} if data.present?
    data
  end

  #
  # { stage1: {project_name1: 2, project_name2: 4}, stage2: {project_name1: 4, project_name2: 2}}
  #
  def self.lead_stage_project_wise_leads_count(current_user, matcher={})
    matcher = matcher.merge(Lead.user_based_scope(current_user))
    matcher = matcher.with_indifferent_access
    data = Lead.collection.aggregate([
      {'$match': matcher},
      {
        '$lookup': {
          from: "projects",
          let: { project_id: "$project_id" },
          pipeline: [
            { '$match': { '$expr': { '$eq': [ "$_id",  "$$project_id" ] } } },
            { '$project': { project_name: '$name' } }
          ],
          as: "projects"
        }
      },
      {
        '$replaceRoot': {
          newRoot: {
            '$mergeObjects': [
              { '$arrayElemAt': [ "$projects", 0 ] },
              "$$ROOT"
            ]
          }
        }
      },
      { '$project': { project_name: 1, project_id: 1, lead_stage: 1 } },
      {'$group': {
        _id: { stage: '$lead_stage', project_name: '$project_name' },
        count: { '$sum': 1 }
      } },
      {'$group': {
        _id: { stage: '$_id.stage' },
        total_count: { '$sum': '$count' },
        project_wise: { '$push': {'project_name': '$_id.project_name', count: { '$sum': '$count' }} }
      } }
    ]).to_a
    o_data = data.inject({}) do |hsh, x|
      hsh[x.dig('_id', 'stage')] ||= {}
      hsh[x.dig('_id', 'stage')] = x['project_wise'].inject({}) do |ihsh, ix|
        ihsh[ix['project_name']] ||= 0
        ihsh[ix['project_name']] += ix['count']
        ihsh
      end
      hsh
    end
    o_data
  end

  def self.project_wise_lead_stage_leads_count(current_user, matcher={})
    matcher = matcher.with_indifferent_access
    data = Lead.collection.aggregate([
      { '$match': Lead.user_based_scope(current_user)},
      { '$match': matcher },
      { '$project': { project_id: '$project_id', lead_stage: '$lead_stage', '_id': 0 } },
      { '$group':
        {
          _id: '$project_id',
          stage: { '$push': '$lead_stage'}
        }
      },
      {
        '$lookup': {
          from: "projects",
          let: { project_id: "$_id" },
          pipeline: [
            { '$match': { '$expr': { '$eq': [ "$_id",  "$$project_id" ] } } },
            { '$project': { project_name: '$name' } }
          ],
          as: "projects"
        }
      },
      {
        '$replaceRoot': {
          newRoot: {
            '$mergeObjects': [
              { '$arrayElemAt': [ "$projects", 0 ] },
              "$$ROOT"
            ]
          }
        }
      },
      { '$project': { project_name: 1, stage: 1 } }
    ]).to_a
    out = []
    data.each do |d|
      stage_count = d[:stage].compact.inject({}) do |ihsh, ix|
        ihsh[ix] ||= 0
        ihsh[ix] += 1
        ihsh
      end
      out << {project_id: d["_id"], project_name: d["project_name"], stage_count: stage_count || {}}.with_indifferent_access
    end
    stages = Lead.distinct(:lead_stage).compact
    return [ out, stages ]
  end

  def self.project_wise_booking_data(current_user, options={})
    matcher = { manager_id: current_user.id, status: {'$nin': %w(hold cancelled swapped)}}
    matcher = matcher.merge!(options[:matcher]) if options[:matcher].present?
    data = BookingDetail.collection.aggregate([
      {'$match':  matcher.merge(BookingDetail.user_based_scope(current_user)) },
      {'$project': {
         tasks: {
           '$ifNull': [{
             '$filter': {
               input: "$tasks",
               as: "task",
               cond: {
                 '$and': [
                   { '$eq': [ "$$task.key", 'registration_done' ] },
                   { '$eq': [ "$$task.completed", true ] }
                 ]
               }
             }
           }, []]
         },
         project_id: 1,
         agreement_price: 1,
         status: 1
      } },
      {'$group': {
        _id: '$project_id',
        av: { '$sum': '$agreement_price' },
        confirmed: { '$sum': { "$cond": [ {"$eq": ['$status', {"$literal": 'booked_confirmed'}]}, 1, 0 ] }},
        registration_done: { '$sum': { "$cond": [ {"$gte": [{"$size": '$tasks'}, 1]}, 1, 0 ] }},
        count: { '$sum': 1 }
      } },
      {'$group': {
        _id: nil,
        total_av: {'$sum': '$av'},
        total_confirmed: {'$sum': '$confirmed'},
        total_registration_done: {'$sum': '$registration_done'},
        total_count: {'$sum': '$count'},
        project_wise: {'$push': {project_id: '$_id', av: '$av', confirmed: '$confirmed', registration_done: '$registration_done', count: '$count'}}
      } }
    ]).to_a
    data = data.first
    data['project_wise'] = data['project_wise'].inject({}) {|hsh, x| hsh[x['project_id']] = x.except('project_id'); hsh}
    data
  end

  def self.conversion_ratio(current_user, filters={})
    bookings = BookingDetail.where(BookingDetail.user_based_scope(current_user)).booking_stages.where(manager_id: current_user.id).build_criteria(filters).count
    leads = Lead.where(Lead.user_based_scope(current_user)).where(manager_id: current_user.id).build_criteria(filters).count
    conv_ratio = leads.zero? ? 0 : bookings/leads.to_f
    (conv_ratio * 100).round
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

  def self.project_unit_collection_report_data(current_user, options={})
    options = options.with_indifferent_access
    matcher = options[:matcher] || {}
    matcher = matcher.with_indifferent_access
    grouping = {
      project_tower_name: "$project_tower_name",
      unit_configuration_name: "$unit_configuration_name",
      project_id: "$project_id"
    }
    # uncancelled bookings project unit ids for total agreement price
    project_unit_ids = BookingDetail.in(status: ['blocked', 'booked_tentative', 'booked_confirmed', 'scheme_approved', 'scheme_rejected', 'under_negotiation']).distinct(:project_unit_id)
    data = ProjectUnit.collection.aggregate([
      { '$match': ProjectUnit.user_based_scope(current_user) },
      { "$match": matcher },
      { "$addFields":
        {
          booking_may_happen: { "$cond": [ {"$in": ["$_id", project_unit_ids]}, 1, 0 ]}
        }
      },
      {
        "$group":
          {
            "_id": grouping,
            blocked:{ "$sum": { "$cond": [ {"$eq": ['$status', {"$literal": 'blocked'}]}, 1, 0 ] } },
            agreement_price: { "$sum": { "$cond": [
                {
                  "$and":
                  [
                    {"$eq": ['$status', {"$literal": 'blocked'}]},
                    {"$eq": ['$booking_may_happen', 1]}
                  ]
                },
                "$agreement_price", 0
                ] } },
            available: { "$sum": { "$cond": [ {"$in": ['$status', ['available', "management_blocking", "employee"]]}, 1, 0 ] } },
            blocked_project_units:{ "$push": { "$cond": [ {"$eq": ['$status', {"$literal": 'blocked'}]}, "$_id", nil] } },
            total: { "$sum": 1 }
          }
        },{
          "$group":
          {
            "_id": { project_tower_name: "$_id.project_tower_name", project_id: "$_id.project_id" },
            total_blocked: { "$sum": "$blocked" },
            total_available: { "$sum": "$available" },
            total: { "$sum": "$total"},
            total_agreement_price: { "$sum": "$agreement_price" },
            total_blocked_project_units: { "$push": "$blocked_project_units" },
            configuration_wise: { "$push": { unit_configuration_name: "$_id.unit_configuration_name", available: "$available", blocked: "$blocked" }}
          }
        },
        {
          '$lookup': {
            from: "projects",
            let: { project_id: "$_id.project_id" },
            pipeline: [
              { '$match': { '$expr': { '$eq': [ "$_id",  "$$project_id" ] } } },
              { '$project': { project_name: '$name' } }
            ],
            as: "project"
          }
        },
        {
        "$project": {
          total_blocked: "$total_blocked",
          total_available: "$total_available",
          total: "$total",
          total_agreement_price: "$total_agreement_price",
          total_blocked_project_units: "$total_blocked_project_units",
          configuration_wise: "$configuration_wise",
          project_name: {"$arrayElemAt": ["$project.project_name", 0]},
        }
      },
      {
        "$sort": {
          "project_name": 1
        }
      }
      ]).to_a
    out = {}
    out["All Towers"] = {total: 0, sold: 0, unsold: 0, av_sold: 0, collection: 0}
    out["All Towers"][:configuration_wise] = new_unit_configuration_hash(current_user)
    data.each do |_data|
      out[_data["_id"]] = {total: _data["total"], sold: _data["total_blocked"], unsold: _data["total_available"], av_sold: _data["total_agreement_price"]}
      _unit_configuration_hash = new_unit_configuration_hash(current_user)
      _data["configuration_wise"].each do |uc|
        _unit_configuration_hash[uc["unit_configuration_name"]] = {sold: uc["blocked"], unsold: uc["available"]}

      end
      out[_data["_id"]][:configuration_wise] = _unit_configuration_hash
      _blocked_units = _data["total_blocked_project_units"].flatten.compact.map{|id| id.to_s}
      _booking_detail_ids = BookingDetail.where(BookingDetail.user_based_scope(current_user)).where(status: {"$in": BookingDetail::BOOKING_STAGES}, project_unit_id: {"$in": _blocked_units}).pluck(:id)
      out[_data["_id"]][:collection] = Receipt.where(Receipt.user_based_scope(current_user)).in(booking_detail_id: _booking_detail_ids).in(status:["success"]).sum(:total_amount)
      out["All Towers"] = calculate_all_towers(out["All Towers"], out[_data["_id"]], current_user)
    end
    out
  end

  def self.project_wise_invoice_data(current_user, options={})
    matcher = {}
    matcher = options[:matcher] if options[:matcher].present?
    matcher.merge!(Invoice.user_based_scope(current_user))
    data = Invoice.collection.aggregate([
      { '$match' =>  matcher},
      {
        '$lookup': {
          from: "projects",
          let: { project_id: "$project_id" },
          pipeline: [
            { '$match': { '$expr': { '$eq': [ "$_id",  "$$project_id" ] } } },
            { '$project': { project_name: '$name' } }
          ],
          as: "projects"
        }
      },
      {
        '$replaceRoot': {
          newRoot: {
            '$mergeObjects': [
              { '$arrayElemAt': [ "$projects", 0 ] },
              "$$ROOT"
            ]
          }
        }
      },
      { '$project': { project_name: 1, status: 1, amount: 1, net_amount: 1 } },
      { '$group' => {
          '_id' => { project_name: '$project_name', status: '$status' },
          count: { '$sum': 1 }, amount: { '$sum': '$amount' }, net_amount: { '$sum': '$net_amount' }
        }
      }
    ]).to_a
    data.map {|x| x.merge(x.delete('_id')).with_indifferent_access}
  end

  def self.project_wise_incentive_deduction_data(current_user, options={})
    matcher = {}
    matcher = options[:matcher] if options[:matcher].present?
    if options[:matcher].present? && current_user.project_ids.present?
      invoice_ids = Invoice.where(Invoice.user_based_scope(current_user)).distinct(:id)
      options[:matcher][:invoice_id] = {"$in": invoice_ids} if invoice_ids.present?
    end
    data = IncentiveDeduction.collection.aggregate([
      {'$match': matcher.merge(IncentiveDeduction.user_based_scope(current_user)) },
      {
        '$lookup': {
          from: "invoices",
          let: { invoice_id: "$invoice_id" },
          pipeline: [
            { '$match': { '$expr': { '$eq': [ "$_id",  "$$invoice_id" ] } } },
            { '$project': { project_id: 1 } },
            {
              '$lookup': {
                from: 'projects',
                let: { project_id: "$project_id" },
                pipeline: [
                  { '$match': { '$expr': { '$eq': [ "$_id",  "$$project_id" ] } } },
                  { '$project': { project_name: '$name' } }
                ],
                as: "projects"
              }
            },
            {
              '$replaceRoot': {
                newRoot: {
                  '$mergeObjects': [
                    { '$arrayElemAt': [ "$projects", 0 ] },
                    "$$ROOT"
                  ]
                }
              }
            },
          ],
          as: "invoices"
        }
      },
      {
        '$replaceRoot': {
          newRoot: {
            '$mergeObjects': [
              { '$arrayElemAt': [ "$invoices", 0 ] },
              "$$ROOT"
            ]
          }
        }
      },
      { '$project': { project_name: 1, amount: 1, status: 1 } },
      { '$group' => {
          '_id' => { project_name: '$project_name', status: '$status' },
          count: { '$sum': 1 }, amount: { '$sum': '$amount' }
        }
      }
    ]).to_a
    data.map {|x| x.merge(x.delete('_id')).with_indifferent_access}
  end

  def self.project_wise_invoice_ageing_data(current_user, options={})
    matcher = {
                status: 'pending_approval',
                raised_date: {'$lt': Date.current}
              }
    matcher = matcher.merge!(options[:matcher]) if options[:matcher].present?
    matcher.merge!(Invoice.user_based_scope(current_user))
    data = Invoice.collection.aggregate([
      { '$match' => matcher },
      {
        '$project': {
          status: 1,
          project_id: 1,
          age: {
            '$trunc': {
              '$divide': [{ '$subtract': [Date.current, '$raised_date'] }, 1000 * 60 * 60 * 24]
            }
          }
        }
      },
      {
        '$lookup': {
          from: "projects",
          let: { project_id: "$project_id" },
          pipeline: [
            { '$match': { '$expr': { '$eq': [ "$_id",  "$$project_id" ] } } },
            { '$project': { project_name: '$name' } }
          ],
          as: "projects"
        }
      },
      {
        '$replaceRoot': {
          newRoot: {
            '$mergeObjects': [
              { '$arrayElemAt': [ "$projects", 0 ] },
              "$$ROOT"
            ]
          }
        }
      },
      {
        '$group': {
          '_id': { age: '$age', project_name: '$project_name' },
          count: { '$sum': 1 }
        }
      }
    ]).to_a
    data.map {|x| x.merge(x.delete('_id')).with_indifferent_access}
  end

  def self.subscribed_count_project_wise(current_user, matcher)
    data = InterestedProject.collection.aggregate([
      {
        "$match": matcher.merge(InterestedProject.user_based_scope(current_user))
      },
        {
        '$group': {
          _id: {
            'project_id': '$project_id'
          },
          count: {
          '$sum': 1
          }
        }
      }
    ]).to_a
    data.map {|x| [x["_id"]["project_id"], x["count"]]}.to_h
  end

  def self.typology_and_inventory_summary(options = {})
    matcher = options[:matcher].with_indifferent_access rescue {}
    created_at = matcher[:dates]
    actual_inventory = self.typology_and_inventory_actual_data(created_at)
    mrp_data = self.typology_and_inventory_mrp_data(created_at, options[:is_token_report])
    booking_data = self.typology_and_inventory_booking_data(created_at)
    actual_inventory.map do |data|
      mrp = mrp_data.select{ |d| d['mrp_id'] == data['actual_id']}
      booking = booking_data.select{ |d| d['booking_id'] == data['actual_id']}
      data.merge!(mrp[0].with_indifferent_access) if mrp.present?
      data.merge!(booking[0].with_indifferent_access) if booking.present?
    end
    actual_inventory
  end

  def self.calculate_booking_percentage(data,floor_band)
    percentage = (((data["booking_#{floor_band}"]/data["actual_#{floor_band}"].to_f) * 100).round rescue 0)
    (percentage.to_f.nan? ? 0.0 : percentage)
  end

  def self.calculate_fill_booking(typology_and_inventory_summary_data, floor_band)
    booking_floor_band_total = (typology_and_inventory_summary_data.map{|d| d["booking_#{floor_band}"] }.compact.sum rescue 0)
    actual_floor_band_total = (typology_and_inventory_summary_data.map{|d| d["actual_#{floor_band}"] }.compact.sum rescue 0)
    fill_mrp_total = ((booking_floor_band_total/actual_floor_band_total.to_f) * 100).round(2)
    (fill_mrp_total.to_f.nan? ? 0.0 : fill_mrp_total)
  end

  def self.calculate_fill_booking_total(typology_and_inventory_summary_data)
    booking_floor_band_total = (typology_and_inventory_summary_data.map{|d| d["booking_total"] }.compact.sum rescue 0)
    actual_floor_band_total = (typology_and_inventory_summary_data.map{|d| d["actual_total"] }.compact.sum rescue 0)
    fill_mrp_total = ((booking_floor_band_total/actual_floor_band_total.to_f) * 100).round(2)
    (fill_mrp_total.to_f.nan? ? 0.0 : fill_mrp_total)
  end

  def self.typology_and_inventory_actual_data(created_at = nil)
    data = ProjectUnit.collection.aggregate([
      {
        "$unwind": "$data"
      },
      {
        "$match": { "data.key": "floor_band" }
      },
      {
        "$group": {
          "_id": { "unit_configuration_name": "$unit_configuration_name", "configuration": "$data.absolute_value" },
            "booking_count": { "$sum": 1 }
        }
      },
       { '$sort': { '_id.unit_configuration_name': 1}}
    ]).as_json
    processed_data = floor_band_process_data(data, "booking_count")
    data = process_data(processed_data, "actual")
    data
  end

  def self.typology_and_inventory_mrp_data(created_at = nil, is_token_report = nil)
    matcher = { "$and": [{ "status": { "$in":  %w[success clearance_pending] } }, { "token_number": { "$nin": [nil, ''] } }] }
    matcher[:booking_detail_id] = nil if is_token_report.present?
    if created_at.present?
      start_date, end_date = created_at.split(' - ')
      matcher = matcher.merge({ "created_at": { "$gte": (Date.parse(start_date).beginning_of_day), "$lte": (Date.parse(end_date).end_of_day)} })
    end
    data = Receipt.collection.aggregate([
      { "$match": matcher },
      {
        '$lookup': {
          "from": "user_kycs",
          "let": { "receipt_id": "$_id" },
          "pipeline": [
            { '$match': { '$expr': { '$eq': [ "$receipt_id",  "$$receipt_id" ] } } },
            { '$project': { "configuration": { '$arrayElemAt': ['$configurations', 0] }, "preferred_floor_band": { '$arrayElemAt': ['$preferred_floor_band', 0] } } }
          ],
          "as": "user_kycs"
        }
      },
      {
        '$replaceRoot': {
          "newRoot": {
            '$mergeObjects': [
              { '$arrayElemAt': [ "$user_kycs", 0 ] },
              "$$ROOT"
            ]
          }
        }
      },
      {
        "$group": {
          "_id": { "unit_configuration_name": "$configuration", "configuration": "$preferred_floor_band" },
            "booking_count": { "$sum": 1 }
        }
      },
       { '$sort': { '_id.unit_configuration_name': 1}}
    ]).as_json
    processed_data = floor_band_process_data(data, "booking_count")
    data = process_data(processed_data, "mrp")
    data
  end

  def self.floor_band_process_data(data_to_process, count)
    processed_data = {}
    data_to_process.each do |data|
      if data['_id'].present? && data['_id']['unit_configuration_name'].present?
        if processed_data[data['_id']['unit_configuration_name']].present?
          processed_data[data['_id']['unit_configuration_name']].merge!({ "#{data['_id']['configuration'].to_f.to_i}": data[count] }.with_indifferent_access)
        else
          processed_data[data['_id']['unit_configuration_name']] = { "#{data['_id']['configuration'].to_f.to_i}": data[count] }.with_indifferent_access
        end
      end
    end
    processed_data
  end

  def self.process_data(hash = {}, prefix = "")
    hash.each do |key,value|
     I18n.t("mongoid.attributes.project_unit.floor_bands").keys.sort.map(&:to_s).each do |floor_band|
       value.merge!("#{floor_band}" => 0) unless value.has_key?(floor_band)
     end
     value = value.sort.to_h
     value.merge!("total" => value.values.sum)
     value.merge!("id" => key)
     hash[key] = value
   end if hash.present?
   converted_array = hash.values
   converted_array.each{|a| a.transform_keys!{|key| "#{prefix}_#{key}" }}
   converted_array
 end

  def self.typology_and_inventory_booking_data(created_at = nil)
    matcher = {status: { "$in": BookingDetail::BOOKING_STAGES } }
    if created_at.present?
      start_date, end_date = created_at.split(' - ')
      matcher = matcher.merge({ "created_at": { "$gte": (Date.parse(start_date).beginning_of_day), "$lte": (Date.parse(end_date).end_of_day)} })
    end
    data = BookingDetail.collection.aggregate([
      {
       "$match": matcher
      },
      {
        "$unwind": "$data"
      },
      {
        "$match": { "data.key": "floor_band" }
      },
      {
        "$lookup": {
          "from": "project_units",
          "let": { "project_unit_id": "$project_unit_id" },
          "pipeline": [
            { '$match': { '$expr': { '$eq': [ "$_id",  "$$project_unit_id" ] } } },
            { '$project': { "configuration": "$unit_configuration_name" } }
          ],
          "as": "project_units"
        }
      },
      {
        "$replaceRoot": {
          "newRoot": {
            '$mergeObjects': [
              { '$arrayElemAt': [ "$project_units", 0 ] },
              "$$ROOT"
            ]
          }
        }
      },
      {
        "$group": {
          "_id": { "unit_configuration_name": "$configuration", "configuration": "$data.absolute_value" },
            "booking_count": { "$sum": 1 }
        }
      },
       { '$sort': { '_id.unit_configuration_name': 1}}
    ]).as_json
    processed_data = floor_band_process_data(data, "booking_count")
    data = process_data(processed_data, "booking")
    data
  end

  def self.calculate_percentage(data,floor_band)
    percentage = (((data["mrp_#{floor_band}"]/data["actual_#{floor_band}"].to_f) * 100).round rescue 0)
    (percentage.to_f.nan? ? 0.0 : percentage)
  end

  def self.calculate_total_percentage(data)
    percentage = (((data["mrp_total"]/data["actual_total"].to_f) * 100).round rescue 0)
    (percentage.to_f.nan? ? 0.0 : percentage)
  end

  def self.calculate_fill_mrp(typology_and_inventory_summary_data, floor_band)
    mrp_floor_band_total = (typology_and_inventory_summary_data.map{|d| d["mrp_#{floor_band}"] }.compact.sum rescue 0)
    actual_floor_band_total = (typology_and_inventory_summary_data.map{|d| d["actual_#{floor_band}"] }.compact.sum rescue 0)
    fill_mrp_total = ((mrp_floor_band_total/actual_floor_band_total.to_f) * 100).round(2)
    (fill_mrp_total.to_f.nan? ? 0.0 : fill_mrp_total)
  end

  def self.bookings_with_completed_tasks_list(matcher = {})
    matcher = matcher.deep_symbolize_keys
    matcher.merge!({status: 'booked_confirmed', task_list_completed: {'$ne': nil}})
    data = BookingDetail.collection.aggregate([
      { '$match': matcher },
      {
      "$group": {
        "_id": {
          "task_list_completed": "$task_list_completed"
        },
        count: {
          "$sum": 1
        }
      }
    },{
      "$sort": {
        "_id.task_list_completed": 1
      }
    }]).to_a
    out = []
    data.each do |d|
      out << { task_list_completed: d["_id"]["task_list_completed"], count: d["count"] }.with_indifferent_access
    end
    out
  end

  def self.todays_booking_count(status = nil, matcher = {})
    _matcher = {booking_portal_client_id: matcher[:booking_portal_client_id]}
    _matcher[:status] = status.present? ? { "$in": [status] } : { "$in": BookingDetail::BOOKING_STAGES }
    _matcher[:created_at] = {
      "$gte": Date.today.beginning_of_day,
      "$lte": Date.today.end_of_day
    }
    _matcher[:project_id] = {"$in": matcher[:project_ids].map{|id| BSON::ObjectId(id) }} if matcher[:project_ids].present?
    BookingDetail.where(_matcher).count
  end

  def self.total_booking_count(status = nil, matcher = {})
    _matcher = {booking_portal_client_id: matcher[:booking_portal_client_id]}
    _matcher[:status] = status.present? ? { "$in": [status] } : { "$in": BookingDetail::BOOKING_STAGES }
    if matcher[:created_at].present?
      start_date, end_date = matcher[:created_at].split(' - ')
      _matcher[:created_at] = {
        "$gte": Date.parse(start_date).beginning_of_day,
        "$lte": Date.parse(end_date).end_of_day
      }
    end
    _matcher[:project_id] = {"$in": _matcher[:project_ids].map{|id| BSON::ObjectId(id) }} if _matcher[:project_ids].present?
    BookingDetail.where(_matcher).count
  end

  protected

  def self.calculate_all_towers all_towers_out, current_tower_data, current_user
    all_towers_out[:total] += current_tower_data[:total]
    all_towers_out[:sold] += current_tower_data[:sold]
    all_towers_out[:unsold] += current_tower_data[:unsold]
    all_towers_out[:av_sold] += current_tower_data[:av_sold]
    all_towers_out[:collection] += current_tower_data[:collection]
    ProjectUnit.where(ProjectUnit.user_based_scope(current_user)).distinct(:unit_configuration_name).sort.each do |uc|
      all_towers_out[:configuration_wise][uc][:sold] += current_tower_data[:configuration_wise][uc][:sold]
      all_towers_out[:configuration_wise][uc][:unsold] += current_tower_data[:configuration_wise][uc][:unsold]
    end
    all_towers_out
  end

  def self.new_unit_configuration_hash current_user
    _unit_configuration_hash = {}
    ProjectUnit.where(ProjectUnit.user_based_scope(current_user)).distinct(:unit_configuration_name).sort.each do |uc|
      _unit_configuration_hash[uc] = {sold: 0, unsold: 0}
    end
    _unit_configuration_hash
  end

  def get_matcher
    # GENERICTODO
  end

end
