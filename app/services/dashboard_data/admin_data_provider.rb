module DashboardData
  class AdminDataProvider
    class << self
      def site_visits_count(user)
        SiteVisit.where(SiteVisit.user_based_scope(user)).count
      end

      def bookings_count(user)
        BookingDetail.where(BookingDetail.user_based_scope(user)).count
      end

      def channel_partner_count(user=nil, project_ids=nil)
        if project_ids.present?
          InterestedProject.where(InterestedProject.user_based_scoped(current_user)).approved.in(project_id: project_ids).count
        else
          User.in(role: %w(channel_partner cp_owner)).where(booking_portal_client: user.booking_portal_client).count
        end
      end

      def sold_project_units_count(user=nil)
        BookingDetail.where(status: {"$in": %w[blocked booked_tentative booked_confirmed under_negotiation]}, booking_portal_client: user.booking_portal_client).count
      end

      def all_project_units_count(user=nil)
        ProjectUnit.not_in(status: 'not_available').where(booking_portal_client: user.booking_portal_client).count
      end

      def open_user_requests(user=nil)
        UserRequest.where(status: 'pending', booking_portal_client: user.booking_portal_client).count
      end

      def online_receipts
        Receipt.where(Receipt.user_based_scoped(current_user)).where(payment_mode: 'online').count
      end

      def offline_receipts
        Receipt.where(Receipt.user_based_scoped(current_user)).not_in(payment_mode: 'online').count
      end

      def active_schemes(user=nil)
        Scheme.approved.where(booking_portal_client: user.booking_portal_client).count
      end

      def receipt_block(user, params)
        matcher = {}
        if params && params[:dates].present?
          dates = params[:dates].split(" - ")
          start_date = Date.strptime(dates[0], '%d/%m/%Y')
          end_date = Date.strptime(dates[1], '%d/%m/%Y')
          matcher = {"created_at": {"$gte": start_date, "$lt": end_date}}
        end
        if params[:payments] == 'attached_payments'
          matcher = {"booking_detail_id" => {"$not" => {"$eq" => nil}}}
        elsif params[:payments] == 'direct_payments'
          matcher = {"booking_detail_id": nil}
        end
        grouping = {
          payment_mode: "$payment_mode",
          status: "$status"
        }
        data = Receipt.collection.aggregate([
                { "$match": matcher.merge(Receipt.user_based_scope(user)) },
                {
                  "$group": 
                  {
                    "_id": grouping,
                    total_amount: {"$sum": "$total_amount"},
                    count: 
                    {
                      "$sum": 1
                    }
                  }
                }, 
                {
                  "$project": 
                  {
                    total_amount: "$total_amount",
                    payment_mode: "$payment_mode",
                    status: "$status",
                    count: "$count"
                  }
                }
              ]).to_a
        out = Hash.new
        data.each do |d|
          if out[(d["_id"]["payment_mode"]).to_sym].present?
            out[(d["_id"]["payment_mode"]).to_sym].merge!(((d["_id"]["status"]).to_sym) => d["count"])
          else
           out[(d["_id"]["payment_mode"]).to_sym] = Hash.new
           out[(d["_id"]["payment_mode"]).to_sym][(d["_id"]["status"]).to_sym]= d['count']
          end
        end
        out
      end

      def project_unit_block(user)
        group_project_unit_with_tower_and_configuration = {
          project_tower_name: "$project_tower_name",
          unit_configuration_name: '$unit_configuration_name',
          status: "$status"
        }
        matcher_for_booked_units = ProjectUnit.user_based_scope(user)

        data = ProjectUnit.collection.aggregate([{"$match": matcher_for_booked_units},
          {
            "$group": 
            {
              "_id": group_project_unit_with_tower_and_configuration,
              count: 
              {
                "$sum": 1
              }
            }
          },
          {
            "$project": {
              unit_configuration_name: "$unit_configuration_name",
              count: "$count",
              status: "$status"
            }
          }
         ]).to_a
        out = Hash.new
        data.each do |d|
          d["count"] = -(d["count"]) if (d["_id"]["status"]) != 'blocked'
          if out[(d["_id"]["project_tower_name"]).to_sym].present?
            out[(d["_id"]["project_tower_name"]).to_sym].merge!(((d["_id"]["unit_configuration_name"]).to_sym) => d["count"])
          else
           out[(d["_id"]["project_tower_name"]).to_sym] = Hash.new
           out[(d["_id"]["project_tower_name"]).to_sym][(d["_id"]["unit_configuration_name"]).to_sym]= d['count']
          end
        end
        out
      end

      def booking_detail_block(user, params)
        matcher = {}
        if params && params[:dates].present?
          dates = params[:dates].split(" - ")
          start_date = Date.strptime(dates[0], '%d/%m/%Y')
          end_date = Date.strptime(dates[1], '%d/%m/%Y')
          matcher = {"created_at": {"$gte": start_date, "$lt": end_date}}
        end
        group_booking_detail_with_tower_and_status = {
          project_tower_name: "$project_tower_name",
          status: "$status"
         }

        data = BookingDetail.collection.aggregate([
          {"$match": matcher.merge(BookingDetail.user_based_scope(user))},
          {
            "$group": {
              "_id": group_booking_detail_with_tower_and_status,
              count: {
                "$sum": 1
              }
            }
          },
          {
            "$project": {
              status: "$status",
              count: "$count"
            }
          }
        ]).to_a
        out = Hash.new
        data.each do |d|
          if d["_id"]["project_tower_name"].present?
            if out[(d["_id"]["project_tower_name"]).to_sym].present?
              out[(d["_id"]["project_tower_name"]).to_sym].merge!(((d["_id"]["status"]).to_sym) => d["count"])
            else
              out[(d["_id"]["project_tower_name"]).to_sym] = Hash.new
              out[(d["_id"]["project_tower_name"]).to_sym][(d["_id"]["status"]).to_sym]= d['count']
            end
          end
        end
        out
      end

      def receipt_piechart user, params
        matcher = {}
        if params && params[:dates].present?
          dates = params[:dates].split(" - ")
          start_date = Date.strptime(dates[0], '%d/%m/%Y')
          end_date = Date.strptime(dates[1], '%d/%m/%Y')
          matcher = {"created_at": {"$gte": start_date, "$lt": end_date}}
        end
        grouping = {
          status: "$status"
        }

        data = Receipt.collection.aggregate([
          { "$match": matcher.merge(Receipt.user_based_scope(user)) },
          {
            "$group": 
            {
              "_id": grouping,
              total_amount: {"$sum": "$total_amount"},
              count: 
              {
                "$sum": 1
              }
            }
          }, 
          {
            "$project": {
              total_amount: "$total_amount",
              status: "$status",
              count: "$count"
            }
          }
        ]).to_a
        out = Hash.new
        data.each do |d|
          out[d["_id"]["status"]] = { total_amount: d['total_amount'], count: d["count"]}
        end
        out
      end

      def user_block(user)
        data = User.collection.aggregate([
          { "$match": matcher.merge(User.user_based_scope(user)) },
          { "$unwind": "$portal_stages" },
          {
            "$sort": { 'portal_stages.created_at': 1 } 
          },
          {
            "$project": 
            {
              stage: "$portal_stages.stage"
            }
          },
          {
            "$group":{
              "_id": "$stage",
              count: {
                "$sum": 1
              }
            }
          }
        ]).to_a
        out = Hash.new
        stages = PortalStagePriority.order(priority: :asc).pluck(:stage)
        stages.each do |stage|
          out[stage] = data.select{|d| d["_id"] == stage}.first["count"] rescue 0
        end
        out
      end

      def receipt_frequency(user, params)
        matcher = {created_at: {"$gt": Date.today - 7.days}}
        grouping = {
          year: { "$year": "$created_at"},
          month: {"$month": "$created_at"},
          week: {"$week": "$created_at"},
          created_at: { "$dayOfMonth": "$created_at" },
          payment_mode: "$payment_mode"
        }
        sort = {
          "_id.year": 1,
          "_id.month": 1,
          "_id.week": 1,
          "_id.created_at": 1
        }
        if params[:frequency] == 'last_7_months'
          matcher = {created_at: {"$gt": DateTime.now - 7.months}}
          grouping = {
            year: { "$year": "$created_at"},
            created_at: {"$month": "$created_at"},
            payment_mode: "$payment_mode"
          }
          sort = {
            "_id.year": 1,
            "_id.created_at": 1
          }
        elsif  params[:frequency] == 'last_7_weeks'
          matcher = {created_at: {"$gt": DateTime.now - 7.weeks}}
          grouping = {
            year: { "$year": "$created_at"},
            month: {"$month": "$created_at"},
            created_at: {"$week": "$created_at"},
            payment_mode: "$payment_mode"
          }
          sort = {
            "_id.year": 1,
            "_id.month": 1,
            "_id.created_at": 1
          }
        elsif params[:frequency] == 'custom_dates'
          if params[:dates].present?
            dates = params[:dates].split(" - ")
            start_date = Date.strptime(dates[0], '%d/%m/%Y')
            end_date = Date.strptime(dates[1], '%d/%m/%Y')
            matcher = {"created_at": {"$gte": start_date, "$lt": end_date}}
          end
        end
        if params[:payments] == 'attached_payments'
          matcher ["booking_detail_id"] = Hash.new
          matcher ["booking_detail_id"]["$not"] = Hash.new
          matcher ["booking_detail_id"]["$not"]["$eq"] = nil
        elsif params[:payments] == 'direct_payments'
          matcher["booking_detail_id"] = nil
        end
        data = Receipt.collection.aggregate([{ "$match": matcher.merge(Receipt.user_based_scope(user)) },
            {
              "$project":{
                payment_mode: 
                {
                  "$cond": 
                  {
                    if: { "$eq": [ "online", "$payment_mode" ] },
                    then: "online",
                    else: "offline"
                  }
                },
                created_at: "$created_at"
              }
            },
            {
              "$group":{
                "_id": grouping,  
                total_amount: {"$sum": "$total_amount"},
                count: {
                  "$sum": 1
                }
              }
            },
            {
              "$sort": sort
            },
            {
              "$project": {
                payment_mode: "$payment_mode",
                status: "$status",
                count: "$count",
                created_at: "$created_at"
              }
            }]).to_a
          out = Hash.new
          data.each do |d|
            if out[(d["_id"]["created_at"])].present?
              out[(d["_id"]["created_at"])].merge!(((d["_id"]["payment_mode"]).to_sym) => d["count"])
            else
             out[(d["_id"]["created_at"])] = Hash.new
             out[(d["_id"]["created_at"])][(d["_id"]["payment_mode"]).to_sym]= d['count']
            end
          end
          out
      end
    end
  end
end
