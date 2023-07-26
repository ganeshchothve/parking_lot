module BookingProgressReport
  def self.unit_configuration_amount_data
    configurations = UserKyc::CONFIGURATIONS
    configuration_hash = {}
    configurations.each do |conf|
      project_unit = ProjectUnit.where(unit_configuration_name: conf).first
      configuration_hash[conf] = { ba_1: PaymentType.where(name: 'ba_1').try(:first).try(:value, project_unit), ba_2: PaymentType.where(name: 'ba_2').try(:first).try(:value, project_unit) }
    end
    configuration_hash.with_indifferent_access
  end

  def self.booking_details_with_configuration
    BookingDetail.collection.aggregate([
      {
        '$lookup': {
          "from": "project_units",
          "let": { "project_unit_id": "$project_unit_id" },
          "pipeline": [
            { '$match': { '$expr': { '$eq': [ "$_id",  "$$project_unit_id" ] } } },
            { '$project': {
                'unit_configuration_name': '$unit_configuration_name'
              }
            }
          ],
          "as": "project_units"
        }
      },
      {
        '$replaceRoot': { newRoot: { '$mergeObjects': [ { '$arrayElemAt': [ "$project_units", 0 ] }, "$$ROOT" ] } }
      },
      {
        '$project': {
          'unit_configuration_name': '$unit_configuration_name'
        }
      }
    ]).as_json
  end

  def self.mrp_count_data(today = false, _matcher = {})
    matcher = _matcher.dup
    created_at = matcher[:dates]
    if today
      current_time = Time.zone.now
      matcher = matcher.merge({ "$and": [{'created_at': { '$gte': current_time.beginning_of_day, '$lte':  current_time.end_of_day } }, { "status": { '$in': ['clearance_pending', 'success'] } }] })
      Receipt.nin(token_number: [nil, '']).where(matcher).count
    else
      if created_at.present?
        start_date, end_date = created_at.split(' - ')
        matcher = matcher.merge({ "$and": [{'created_at': { '$gte': (Date.parse(start_date).beginning_of_day), '$lte': (Date.parse(end_date).end_of_day) } }, { "status": { '$in': ['clearance_pending', 'success'] } }] })
      else
        matcher = matcher.merge({ "status": { '$in': ['clearance_pending', 'success'] } })
      end
      Receipt.nin(token_number: [nil, '']).where(matcher).count
    end
  end

  def self.ba1_ba2_count_data(today = false)
    current_time = Time.zone.now
    processed_payment_data = {}

    matcher = today ? { "$and": [{'created_at': { '$gte': current_time.beginning_of_day, '$lte':  current_time.end_of_day } }, { "status": { '$in': ['clearance_pending', 'success'] } }, { "payment_type": { "$in": ['ba_1', 'ba_2'] } }, { booking_detail_id: {'$nin': [nil, ''] } }] } : { "$and": [{ "status": { '$in': ['clearance_pending', 'success'] } }, { "payment_type": { "$in": ['ba_1', 'ba_2'] } }, { booking_detail_id: {'$nin': [nil, ''] } } ] }

    payment_data = Receipt.collection.aggregate([
      { "$match": matcher },
      {
        "$group": {
          "_id": { "booking_detail_id": "$booking_detail_id", "payment_type": "$payment_type" },
          "amount": { "$sum": "$total_amount" }
        }
      }
    ]).as_json

    payment_data.each do |d|
      if processed_payment_data[d['_id']['booking_detail_id']].present?
        processed_payment_data[d['_id']['booking_detail_id']].merge!({ "#{d['_id']['payment_type']}": d['amount'] })
      else
        processed_payment_data[d['_id']['booking_detail_id']] = { "#{d['_id']['payment_type']}":  d['amount'] }
      end
    end
    processed_payment_data.with_indifferent_access
  end

  def self.calculate_overall_booking_progess_data(configuration_hash, ba1_ba2_data, today = false)
    ba1_count = 0
    ba2_count = 0
    ba1_ba2_data.each do |key, value|
      if value['ba_1'].present? && configuration_hash[value['unit_configuration_name']].try(:[], 'ba_1').present?
        ba1_count = ba1_count + 1 if value['ba_1'] >= configuration_hash[value['unit_configuration_name']]['ba_1']
      end
      if value['ba_2'].present? && configuration_hash[value['unit_configuration_name']].try(:[], 'ba_2').present?
        ba2_count = ba2_count + 1 if value['ba_2'] >= configuration_hash[value['unit_configuration_name']]['ba_2']
      end
    end
    { mrp_count: mrp_count_data(today), ba_1: ba1_count, ba_2: ba2_count }.with_indifferent_access
  end

  def self.data(matcher = {})
    report_data = []
    # configuration_hash = unit_configuration_amount_data
    # booking_configuration_hash = booking_details_with_configuration

    # todays_ba1_ba2_data = ba1_ba2_count_data(true)
    # overall_ba1_ba2_data = ba1_ba2_count_data

    # todays_ba1_ba2_data.each do |key, value|
    #   conf = booking_configuration_hash.select{ |c| c['_id'] == key }
    #   todays_ba1_ba2_data[key].merge!({unit_configuration_name: conf[0]['unit_configuration_name']}) if conf.present?
    # end

    # overall_ba1_ba2_data.each do |key, value|
    #   conf = booking_configuration_hash.select{ |c| c['_id'] == key }
    #   overall_ba1_ba2_data[key].merge!({unit_configuration_name: conf[0]['unit_configuration_name']}) if conf.present?
    # end

    report_data.push({mrp_count: mrp_count_data(true, matcher), ba_1: 0, ba_2: 0 }.with_indifferent_access)
    # todays_ba1_ba2_data.present? ? report_data.push(calculate_overall_booking_progess_data(configuration_hash, todays_ba1_ba2_data, true)) :  report_data.push({mrp_count: mrp_count_data(true), ba_1: 0, ba_2: 0 }.with_indifferent_access)

    report_data.push({mrp_count: mrp_count_data(false, matcher), ba_1: 0, ba_2: 0 }.with_indifferent_access)
    # overall_ba1_ba2_data.present? ? report_data.push(calculate_overall_booking_progess_data(configuration_hash, overall_ba1_ba2_data)) : report_data.push({mrp_count: mrp_count_data, ba_1: 0, ba_2: 0 }.with_indifferent_access)
    report_data
  end
end
