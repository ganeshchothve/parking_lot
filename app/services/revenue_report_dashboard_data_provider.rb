module RevenueReportDashboardDataProvider
  def self.tentative_reports(current_user, params={})
    invoice_matcher = set_invoice_matcher("tentative")
    invoiceable_matcher = set_invoiceable_matcher("tentative")
    project_wise_total_tentative_amount = {}
    data = Invoice.collection.aggregate([
    {
      '$match': invoice_matcher
    },
    {
      '$lookup': {
      'from':  get_resource(params[:resource]="BookingDetail"),
      'let': { 'invoiceable_id': "$invoiceable_id" },
      'pipeline': [
        { '$match': { '$and': [invoiceable_matcher, { '$expr': { '$eq': [ "$_id",  "$$invoiceable_id" ] } }] } },
        {'$project': {'_id': 0, 'invoiceable_id': "$_id"}}
      ],
      'as': "booking_details"
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
      '$project': {'project_id': '$project_id' , 'city': '$city', 'amount': '$amount', 'gst_amount': '$gst_amount', 'net_amount': '$net_amount', 'status': '$status', 'invoiceable_id': '$invoiceable_id'}
    },
    {
      '$group': {
          '_id': '$project_id',
          'net_amount': { '$sum': '$net_amount'},
          'amount': {'$sum': '$amount'},
          'gst_amount': {'$sum': '$gst_amount'},
          'city': {'$first': '$city'},
          'status': {'$first': '$status'},
          'invoiceable_id': {'$first': '$invoiceable_id'}
        }
    }
    ]).as_json

    project_wise_tentative_amount = {}
    data.each do |d|
      if project_wise_tentative_amount[d['city']].present?
        project_wise_tentative_amount[d['city']].push({ project_id: d['_id'], amount: d['amount'] })
      else
        project_wise_tentative_amount[d['city']] = [{ project_id: d['_id'], amount: d['amount'] }]
      end
    end
    project_wise_tentative_amount
  end

  def self.set_invoice_matcher(report_type="tentative", params={resource: "BookingDetail"})
    params = params.with_indifferent_access
    matcher = {}
    matcher[:status] = report_type == "tentative" ? "tentative" : {'$ne': "tentative"}
    matcher[:project_id] = {'$in': params[:project_id].split(",")} if params[:project_id].present?
    matcher[:channel_partner_id] = params[:channel_partner_id] if params[:channel_partner_id].present?
    matcher[:manager_id] = params[:manager_id] if params[:manager_id].present?
    matcher[:cp_manager_id] = params[:cp_manager_id] if params[:cp_manager_id].present?
    matcher[:cp_admin_id] = params[:cp_admin_id] if params[:cp_admin_id].present?
    matcher[:category] = params[:category] if params[:category].present?

    matcher[:invoiceable_type] = params[:resource] || "BookingDetail"

    matcher
  end

  def self.set_invoiceable_matcher(report_type="tentative", params={resource: "BookingDetail"})
    params = params.with_indifferent_access
    matcher = {}
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
