module DashboardDataProvider
  def self.channel_partners_dashboard
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

  def self.receipts_dashboard
    data = Receipt.collection.aggregate([{
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

  def self.users_dashboard
    data = User.collection.aggregate([{
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

  def self.project_units_dashboard
    data = ProjectUnit.collection.aggregate([{
      "$group": {
        "_id": {
          status: "$status",
          bedrooms: "$bedrooms"
        },
        agreement_price: {
          "$addToSet": "$agreement_price"
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
        bedrooms: "$bedrooms",
        status: "$status",
        count: "$count"
      }
    }]).to_a
    out = []
    data.each do |d|
      out << {bedrooms: d["_id"]["bedrooms"], status: d["_id"]["status"], count: d["count"], total_agreement_price: d["total_agreement_price"]}.with_indifferent_access
    end
    out
  end

  protected
  def get_matcher
    # GENERICTODO
  end
end
