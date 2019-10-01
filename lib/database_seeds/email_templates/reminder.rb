module DatabaseSeeds
  module EmailTemplates
    module Reminder
      def self.seed client_id
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "User", name: 'not_confirmed_day_1', subject: 'Mahindra Happinest | Complete your MRP registration today', 
          content: "<div class = 'card'>
                <div class = 'card-body'>
                  Dear <%= self.name %>,<br/>
                  Thank you for showing interest in Happinest Kalyan. We have received your details but your MRP registration is not complete. Please note that MRP is mandatory to be eligible for home booking and additional benefits at Happinest Kalyan.<br/>
                  To continue to MRP registration, visit <a href = 'book.mahindrahappinest.com'> book.mahindrahappinest.com</a><br/>
                  To know more about the MRP process and how to gain maximum benefits, watch this short video or download this PDF.<br/>
                  For any further queries, please mail us at <%= self.booking_portal_client.support_email %> or call on <%= self.booking_portal_client.support_number %>.<br/>
                  <Standard T&Cs>
                </div>
              </div>") if ::Template::EmailTemplate.where(name: "not_confirmed_day_1").blank?
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "User", name: 'not_confirmed_day_3', subject: 'Mahindra Happinest |  Do you want to be first or last?', 
          content: "<div class = 'card'>
                <div class = 'card-body'>
                  Dear <%= self.name %>,<br/>
                  We have received your details but your MRP registration is not complete. Please note that MRP is mandatory to be eligible for home booking and additional benefits at Happinest Kalyan.<br/>
                  Under our Accelerated Benefits program, people are given rewards on a first come first serve basis. This means those who register early stand to gain more benefits compared to those who join the queue later.<br/>
                  To complete your MRP registration, visit <a href = 'book.mahindrahappinest.com'> book.mahindrahappinest.com</a><br/>
                  To know more about the MRP process and how to gain maximum benefits, watch this short video or download this PDF.<br/>
                  For any further queries, please mail us at <%= self.booking_portal_client.support_email %> or call on <%= self.booking_portal_client.support_number %>.<br/>
                  <Standard T&Cs>
                </div>
              </div>") if ::Template::EmailTemplate.where(name: "not_confirmed_day_3").blank?
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "User", name: 'not_confirmed_day_5', subject: 'Mahindra Happinest | One step closer to your dream home', 
          content: "<div class = 'card'>
                <div class = 'card-body'>
                  Dear <%= self.name %>,<br/>
                  Thank you for showing interest in Happinest Kalyan. We have received your details but your MRP registration is not complete. Please note that MRP is mandatory to be eligible for home booking and additional benefits at Happinest Kalyan.<br/>
                  The MRP program is an initiative from Mahindra to support home buyers like you to make their dream home a reality. To know more about the MRP process and how to gain maximum benefits, watch this short video or download this PDF.<br/>
                  To complete your MRP registration, visit <a href = 'book.mahindrahappinest.com'> book.mahindrahappinest.com</a><br/>
                  For any further queries, please mail us at <%= self.booking_portal_client.support_email %> or call on <%= self.booking_portal_client.support_number %>.<br/>
                  <Standard T&Cs>
                </div>
              </div>") if ::Template::EmailTemplate.where(name: "not_confirmed_day_5").blank?
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "User", name: 'no_payment_hour_1', subject: 'Mahindra Happinest | MRP Not Complete', 
          content: "<div class = 'card'>
                <div class = 'card-body'>
                  Dear <%= self.name %>,<br/>
                  Thank you for creating your account with Happinest Kalyan. Please note your MRP is not complete and you are not yet eligible for saving benefits.<br/><br/>
                  The MRP savings plan is on a first come first serve basis. Each MRP generated has a unique savings attached to it. The earlier you are, the more your benefit as it is linked to your relative position in the queue and the total length of the queue.<br/><br/>
                  We have already generated <%= Receipt.where(booking_detail_id: nil).count %> MRPs so far.<br/>
                  To confirm your savings of Rs. 50,000 and more, complete your MRP generation at <a href = 'book.mahindrahappinest.com'> book.mahindrahappinest.com</a><br/><br/>
                  To know more about MRP, watch this video or download this PDF.<br/><br/>
                  In case of any further queries, please mail us at <%= self.booking_portal_client.support_email %> or call on <%= self.booking_portal_client.support_number %>.<br/><br/>
                  <Standard T&Cs>
                </div>
              </div>") if ::Template::EmailTemplate.where(name: "no_payment_hour_1").blank?

        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "User", name: 'no_payment_day_1', subject: 'Mahindra Happinest | MRP Generation Pending', 
          content: "<div class = 'card'>
                <div class = 'card-body'>
                  Dear <%= self.name %>,<br/>
                  Thank you for creating your account with Happinest Kalyan. Please note that your payment of Rs. 24,000 (fully refundable in case of non-booking) is pending.<br/><br/>
                  The MRP savings plan is on a first come first serve basis. Each MRP generated has a unique savings attached to it. The earlier you are, the more your benefit as it is linked to your relative position in the queue and the total length of the queue. <br/><br/>
                  We have already generated <%= Receipt.where(booking_detail_id: nil).count %> MRPs so far.<br/>
                  To confirm your savings of Rs. 50,000 and more, complete your MRP generation at <a href = 'book.mahindrahappinest.com'> book.mahindrahappinest.com</a><br/><br/>
                  To know more about MRP, watch this video or download this PDF.<br/><br/>
                  In case of any further queries, please mail us at <%= self.booking_portal_client.support_email %> or call on <%= self.booking_portal_client.support_number %>.<br/><br/>
                  <Standard T&Cs>
                </div>
              </div>") if ::Template::EmailTemplate.where(name: "no_payment_day_1").blank?
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "User", name: 'no_payment_day_3', subject: 'Mahindra Happinest | One step to go', 
          content: "<div class = 'card'>
                <div class = 'card-body'>
                  Dear <%= self.name %>,<br/>
                  You are one step away from joining the MRP queue that will allow you to save Rs. 50,000 and more on your home booking at Happinest Kalyan.<br/><br/>
                  The MRP savings plan is on a first come first serve basis. Each MRP generated has a unique savings attached to it. The earlier you are, the more your benefit as it is linked to your relative position in the queue and the total length of the queue. <br/><br/>
                  We have already generated <%= Receipt.where(booking_detail_id: nil).count %> MRPs so far.<br/>
                  To confirm your savings of Rs. 50,000 and more, complete your MRP generation at <a href = 'book.mahindrahappinest.com'> book.mahindrahappinest.com</a><br/><br/>
                  To know more about MRP, watch this video or download this PDF.<br/><br/>
                  In case of any further queries, please mail us at <%= self.booking_portal_client.support_email %> or call on <%= self.booking_portal_client.support_number %>.<br/><br/>
                  <Standard T&Cs>
                </div>
              </div>") if ::Template::EmailTemplate.where(name: "not_payment_day_3").blank?
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "User", name: 'no_booking_day_4', subject: 'Mahindra Happinest | Home loan requirement', 
          content: "<div class = 'card'>
                <div class = 'card-body'>
                  Dear <%= self.name %>,<br/>
                  Thank you for participating in MRP process.<br/><br/>
                  In case if you need a home loan, select loan preference in the MRP form and upload KYC so that our loan representative can help you. Login to give your loan preference on <a href = 'book.mahindrahappinest.com'> book.mahindrahappinest.com</a><br/><br/>
                  We will start the allocation process on  <Allocation start date> and will share all details in a follow up mail.<br/><br/>
                  In case of any queries, please mail us at <%= self.booking_portal_client.support_email %> or call on <%= self.booking_portal_client.support_number %>.<br/><br/>
                  <Standard T&Cs>
                </div>
              </div>") if ::Template::EmailTemplate.where(name: "no_booking_day_4").blank?
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "User", name: 'no_booking_day_5', subject: 'Mahindra Happinest | Get additional discount of Rs.5,000 by completing your profile details', 
          content: "<div class = 'card'>
                <div class = 'card-body'>
                  Dear <%= self.name %>,<br/>
                  The benefits associated with your Multiplier Rebate Plan number <%= self.receipts.where(status: {'$in': %w[pending success clearance_pending]}).first.try(:token_number) %> keeps increasing. Earn additional discount of Rs.5000 at Happinest Kalyan by completing your profile to help us know you better on <a href = 'book.mahindrahappinest.com'> book.mahindrahappinest.com</a><br/><br/>
                  We will start the allocation process on <date.> and will share all details in a follow up mail.<br/><br/>
                  In case of any queries, please mail us at <%= self.booking_portal_client.support_email %> or call on <%= self.booking_portal_client.support_number %>.<br/><br/>
                  <Standard T&Cs>
                </div>
              </div>") if ::Template::EmailTemplate.where(name: "no_booking_day_5").blank?
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "User", name: 'no_booking_day_6', subject: 'Mahindra Happinest | List of financial partners for home loan requirement', 
          content: "<div class = 'card'>
                <div class = 'card-body'>
                  Dear <%= self.name %>,<br/>
                  Thank for showing your preference for the loan requirement for your dream home at Happinest Kalyan. We have a host financial partners who are offering home loans at competitive rates. Please get in the touch with the financial partners from the list mentioned below.<br/><br/>
                  <ol><li></li><li></li><li></li></ol>
                  In case of any queries, please mail us at <%= self.booking_portal_client.support_email %> or call on <%= self.booking_portal_client.support_number %>.<br/><br/>
                  We will start the allocation process on <date.> and will share all details in a follow up mail.<br/><br/>
                  <Standard T&Cs>
                </div>
              </div>")  if ::Template::EmailTemplate.where(name: "no_booking_day_6").blank?
        Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: "User", name: 'no_booking_day_7', subject: 'Mahindra Happinest | Get additional discount of Rs.20,000 by making your friends your neighbour', 
          content: "<div class = 'card'>
                <div class = 'card-body'>
                  Dear <%= self.name %>,<br/>
                  The benefits associated with your associated with your Multiplier Rebate Plan number <MRP 01201> keeps increasing. Earn additional discount of Rs.20,000 by referring your 3 friends at Happinest Kalyan and making them your neighbours on <a href = 'book.mahindrahappinest.com'> book.mahindrahappinest.com</a><br/><br/>
                  We will start the allocation process on <date.> and will share all details in a follow up mail.<br/><br/>
                  In case of any queries, please mail us at <%= self.booking_portal_client.support_email %> or call on <%= self.booking_portal_client.support_number %>.<br/><br/>
                  <Standard T&Cs>
                </div>
              </div>")  if ::Template::EmailTemplate.where(name: "no_booking_day_7").blank?
      end
    end
  end
end
