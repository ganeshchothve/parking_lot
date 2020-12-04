class ReminderWorker
  include Sidekiq::Worker

  def perform
    send_after_registration_mail_and_sms
    projects = Project.all
    projects.each do |project|
      send_after_kyc_mail_and_sms(project)
      send_after_payment_mail_and_sms(project)
    end
  end

  private
  def send_after_registration_mail_and_sms
    only_registered_users = User.collection.aggregate([{"$match": {'confirmed_at': nil}},
      {"$project":
        {"created_at": {"$trunc": {"$divide": [{ "$subtract": [Date.today, '$created_at'] }, 1000 * 60 * 60 * 24]}}, "id": "$_id"}
      },
      {"$match":
        {"created_at": {"$in": [1,3,5]}}
      },
      {
        "$group": {
          "_id": "$created_at",
          "ids": {
            "$push": "$id"
          }
        }
      }
    ]).to_a
    only_registered_users.each do |group|
      group['ids'].each do |user_id|
        Reminders::PostRegistrationWorker.perform_async user_id, group['_id']
      end
    end
  end

  def send_after_kyc_mail_and_sms(project)
    user_ids_with_payment = project.receipts.where(status: {"$in": %w[clearance_pending success]}).distinct(:user_id)
    only_kyc_done_users = UserKyc.collection.aggregate([
      {
        "$match":{"user_id": {"$nin": user_ids_with_payment}}
      },
      {"$project":
        {"created_at": {"$trunc": {"$divide": [{ "$subtract": [Date.today, '$created_at'] }, 1000 * 60 * 60 * 24]}}, "user_id": "$user_id"}
      },
      {"$match":
        {"created_at": {"$in": [1,3]}}
      },
      {
        "$group": {
          "_id": "$created_at",
          "user_ids": {
            "$push": "$user_id"
          }
        }
      }
    ]).to_a
    only_kyc_done_users.each do |group|
      group['user_ids'].each do |user_id|
        Reminders::PostKycWorker.perform_async user_id, group['_id'], project.id.to_s
      end
    end
  end

  def send_after_payment_mail_and_sms(project)
    user_ids_with_booking = project.booking_details.distinct(:user_id)
    only_payment_done_users = Receipt.collection.aggregate([
      {
        "$match": {"user_id": {"$nin": user_ids_with_booking }}
      },
      {"$project":
        {"created_at": {"$trunc": {"$divide": [{ "$subtract": [Date.today, '$created_at'] }, 1000 * 60 * 60 * 24]}}, "user_id": "$user_id"}
      },
      {"$match":
        {"created_at": {"$in": [4,5,6,7]}}
      },
      {
        "$group": {
          "_id": "$created_at",
          "user_ids": {
            "$push": "$user_id"
          }
        }
      }
    ]).to_a
    only_payment_done_users.each do |group|
      group['user_ids'].each do |user_id|
        Reminders::PostPaymentWorker.perform_async user_id, group['_id'], project.id.to_s
      end
    end
  end
end