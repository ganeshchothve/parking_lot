module RevenueReportDashboardDataProvider
  def self.tentative_reports(current_user, params={})
    invoice_matcher = set_invoice_matcher("tentative", params)
    invoiceable_matcher = set_invoiceable_matcher("tentative", params)
    data = Invoice.collection.aggregate([
    {
      '$match': invoice_matcher
    },
    {
      '$lookup': {
      'from':  get_resource(params[:resource]),
      'let': { 'invoiceable_id': "$invoiceable_id" },
      'pipeline': [
        { '$match': { '$and': [invoiceable_matcher, { '$expr': { '$eq': [ "$_id",  "$$invoiceable_id" ] } }] } },
        {'$project': {'_id': 0, 'invoiceable_id': "$_id", 'agreement_price': '$agreement_price'}}
      ],
      'as': get_resource(params[:resource])
      }
    },
    {
      '$match': { "#{get_resource(params[:resource])}": {'$ne': []}}
    },
    {
      '$replaceRoot': {
        'newRoot': {
          '$mergeObjects': [
            { '$arrayElemAt': [ "$"+"#{get_resource(params[:resource])}", 0 ] },
            "$$ROOT"
          ]
        }
      }
    },
    {
      '$lookup': {
      'from': "projects",
      'let': { 'project_id': "$project_id" },
      'pipeline': [
        { '$match': { '$expr': { '$eq': [ "$_id",  "$$project_id" ] } } },
        { '$project': {'_id': 0, 'project_id': "$_id", 'city': '$city', 'invoiceable_id': '$invoiceable_id' } }
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
    },
    {
      '$project': {'project_id': '$project_id' , 'city': '$city', 'amount': '$amount', 'gst_amount': '$gst_amount', 'net_amount': '$net_amount', 'status': '$status', 'invoiceable_id': '$invoiceable_id', 'agreement_price': '$agreement_price'}
    },
    {
      '$group': {
          '_id': '$project_id',
          'net_amount': { '$sum': '$net_amount'},
          'amount': {'$sum': '$amount'},
          'gst_amount': {'$sum': '$gst_amount'},
          'bookings_count': { '$sum': 1},
          'agreement_price': {'$sum': '$agreement_price'},
          'city': {'$first': '$city'},
          'status': {'$first': '$status'},
          'invoiceable_id': {'$first': '$invoiceable_id'}
        }
    }
    ]).as_json

    project_wise_tentative_amount = {}
    data.each do |d|
      if project_wise_tentative_amount[d['city']].present?
        project_wise_tentative_amount[d['city']].push({ project_id: d['_id'], amount: d['amount'], bookings_count: d['bookings_count'], agreement_price: d['agreement_price'] })
      else
        project_wise_tentative_amount[d['city']] = [{ project_id: d['_id'], amount: d['amount'], bookings_count: d['bookings_count'], agreement_price: d['agreement_price'] }]
      end
    end
    project_wise_tentative_amount
  end

  def self.actual_reports(current_user, params={})
    invoice_matcher = set_invoice_matcher("actual", params)
    invoiceable_matcher = set_invoiceable_matcher("actual", params)
    data = Invoice.collection.aggregate([
    {
      '$match': invoice_matcher
    },
    {
      '$lookup': {
      'from':  get_resource(params[:resource]),
      'let': { 'invoiceable_id': "$invoiceable_id" },
      'pipeline': [
        { '$match': { '$and': [invoiceable_matcher, { '$expr': { '$eq': [ "$_id",  "$$invoiceable_id" ] } }] } },
        {'$project': {'_id': 0, 'invoiceable_id': "$_id"}}
      ],
      'as': get_resource(params[:resource])
      }
    },
    {
      '$match': { "#{get_resource(params[:resource])}": {'$ne': []}}
    },
    {
      '$lookup': {
      'from': "projects",
      'let': { 'project_id': "$project_id" },
      'pipeline': [
        { '$match': { '$expr': { '$eq': [ "$_id",  "$$project_id" ] } } },
        { '$project': {'_id': 0, 'project_id': "$_id", 'city': '$city', 'invoiceable_id': '$invoiceable_id' } }
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
    },
    {
      '$project': {'project_id': '$project_id' , 'city': '$city', 'amount': '$amount', 'gst_amount': '$gst_amount', 'net_amount': '$net_amount', 'status': '$status', 'invoiceable_id': '$invoiceable_id'}
    },
    {
      '$group': {
          '_id': {
            'project_id': '$project_id',
            'status': '$status'
            },
          'amount': {'$sum': '$amount'},
          'city': {'$first': '$city'},
        }
    }
    ]).as_json

    project_wise_actual_amount = {}
    data.each do |d|
      if project_wise_actual_amount.has_key?(d['city'])
        if project_wise_actual_amount[d['city']].has_key?(d['_id']['project_id'])
          project_wise_actual_amount[d['city']][d['_id']['project_id']][d['_id']['status']] = d['amount']
        else
          temp_status_hash = {}
          temp_status_hash[d['_id']['status']] = d['amount']
          project_wise_actual_amount[d['city']][d['_id']['project_id']] = temp_status_hash
        end
      else
        temp_status_hash = {}
        temp_status_hash[d['_id']['status']] = d['amount']
        temp_project_wise_amount_hash = {}
        temp_project_wise_amount_hash[d['_id']['project_id']] = temp_status_hash
        project_wise_actual_amount[d['city']] = temp_project_wise_amount_hash
      end
    end
    project_wise_actual_amount
  end

  def self.set_invoice_matcher(report_type="tentative", params)
    matcher = {}
    matcher[:status] = report_type == "tentative" ? "tentative" : {'$in': Invoice::INVOICE_REPORT_STAGES}
    matcher[:project_id] = {'$in': params[:project_id].map { |id| BSON::ObjectId(id) }} if params[:project_id].present?
    matcher[:channel_partner_id] = params[:channel_partner_id] if params[:channel_partner_id].present?
    matcher[:manager_id] = BSON::ObjectId(params[:manager_id]) if params[:manager_id].present?
    matcher[:cp_manager_id] = BSON::ObjectId(params[:cp_manager_id]) if params[:cp_manager_id].present?
    matcher[:cp_admin_id] = BSON::ObjectId(params[:cp_admin_id]) if params[:cp_admin_id].present?
    matcher[:category] = params[:category] if params[:category].present?

    matcher[:invoiceable_type] = params[:resource].present? ? params[:resource] : "BookingDetail"

    matcher
  end

  def self.set_invoiceable_matcher(report_type="tentative", params)
    matcher = {}
    params[:resource] ||= "BookingDetail"
    case params[:resource]
    when "BookingDetail"
      if params[:agreement_date].present?
        start_date, end_date = params[:agreement_date].split(' - ')
        matcher[:agreement_date] = {
            "$gte": Date.parse(start_date).beginning_of_day,
            "$lte": Date.parse(end_date).end_of_day
        }
      end

      if params[:booked_on].present?
        start_date, end_date = params[:booked_on].split(' - ')
        matcher[:booked_on] = {
            "$gte": Date.parse(start_date).beginning_of_day,
            "$lte": Date.parse(end_date).end_of_day
          }
      end

      matcher[:status] = params[:booking_detail_status] if params[:booking_detail_status].present?

    when "SiteVisit"
      if params[:scheduled_on].present?
        start_date, end_date = params[:scheduled_on].split(' - ')
        matcher[:scheduled_on] = {
            "$gte": Date.parse(start_date).beginning_of_day,
            "$lte": Date.parse(end_date).end_of_day
          }
      end

      if params[:conducted_on].present?
        start_date, end_date = params[:conducted_on].split(' - ')
        matcher[:conducted_on] = {
            "$gte": Date.parse(start_date).beginning_of_day,
            "$lte": Date.parse(end_date).end_of_day
          }
      end

      matcher[:status] = params[:site_visit_status] if params[:site_visit_status].present?

    end

    # common parameter for BookingDetails and SiteVisit
    if params[:created_at].present?
      start_date, end_date = params[:created_at].split(' - ')
      matcher[:created_at] = {
          "$gte": Date.parse(start_date).beginning_of_day,
          "$lte": Date.parse(end_date).end_of_day
        }
    end

    matcher
  end

  def self.get_resource(resource="BookingDetail")
    case resource
    when "BookingDetail"
      "booking_details"
    when "SiteVisit"
      "site_visits"
    when "Lead"
      "leads"
    when "User"
      "users"
    else
      "booking_details"
    end
  end
end
