# frozen_string_literal: true

module DatabaseSeeds
  module EmailTemplates
    module Reminder
      def self.client_based_email_templates_seed(client_id)
        if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, name: 'not_confirmed_day_1').blank?
          Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: 'User', name: 'not_confirmed_day_1', subject: '<%= self.booking_portal_client.name %> | Complete your KYC registration today', content:
            "<div class = 'card'>
              <div class = 'card-body'>
                Dear <%= self.name %>,<br/>
                Thank you for showing interest in <%= current_project.name %>. We have received your details but your KYC registration is not complete. Please note that KYC is mandatory to be eligible for home booking and additional benefits at <%= current_project.name %>.<br/>
                For any further queries, please mail us at <%= self.booking_portal_client.support_email %> or call on <%= self.booking_portal_client.support_number %>.<br/>
                <Standard T&Cs>
              </div>
            </div>")
        end

        if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, name: 'not_confirmed_day_3').blank?
          Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: 'User', name: 'not_confirmed_day_3', subject: '<%= self.booking_portal_client.name %> |  Do you want to be first or last?', content: "<div class = 'card'>
                <div class = 'card-body'>
                  Dear <%= self.name %>,<br/>
                  We have received your details but your KYC registration is not complete. Please note that KYC is mandatory to be eligible for home booking and additional benefits at <%= current_project.name %>.<br/>
                  Under our Accelerated Benefits program, people are given rewards on a first come first serve basis. This means those who register early stand to gain more benefits compared to those who join the queue later.<br/>
                  For any further queries, please mail us at <%= self.booking_portal_client.support_email %> or call on <%= self.booking_portal_client.support_number %>.<br/>
                  <Standard T&Cs>
                </div>
              </div>")
        end

        if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, name: 'not_confirmed_day_5').blank?
          Template::EmailTemplate.create!(booking_portal_client_id: client_id, subject_class: 'User', name: 'not_confirmed_day_5', subject: '<%= self.booking_portal_client.name %> | One step closer to your dream home', content:
            "<div class = 'card'>
              <div class = 'card-body'>
                Dear <%= self.name %>,<br/>
                Thank you for showing interest in <%= current_project.name %>. We have received your details but your KYC registration is not complete. Please note that KYC is mandatory to be eligible for home booking and additional benefits at <%= current_project.name %>.<br/>
                For any further queries, please mail us at <%= self.booking_portal_client.support_email %> or call on <%= self.booking_portal_client.support_number %>.<br/>
                <Standard T&Cs>
              </div>
            </div>")
        end
      end

      def self.project_based_email_templates_seed(project_id, client_id)
        if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: 'no_payment_hour_1').blank?
          Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: 'Lead', name: 'no_payment_hour_1', subject: '<%= self.user.booking_portal_client.name %> | KYC Not Complete', content:
            "<div class = 'card'>
              <div class = 'card-body'>
                Dear <%= self.name %>,<br/>
                Thank you for creating your account with <%= self.project.name %>. Please note your KYC is not complete and you are not yet eligible for saving benefits.<br/><br/>
                In case of any further queries, please mail us at <%= self.user.booking_portal_client.support_email %> or call on <%= self.user.booking_portal_client.support_number %>.<br/><br/>
                <Standard T&Cs>
              </div>
            </div>")
        end

        if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: 'no_payment_day_1').blank?
          Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: 'Lead', name: 'no_payment_day_1', subject: '<%= self.user.booking_portal_client.name %> | KYC Generation Pending', content:
            "<div class = 'card'>
              <div class = 'card-body'>
                Dear <%= self.name %>,<br/>
                Thank you for creating your account with <%= self.project.name %>. Please note that your payment of Rs. 24,000 (fully refundable in case of non-booking) is pending.<br/><br/>
                In case of any further queries, please mail us at <%= self.user.booking_portal_client.support_email %> or call on <%= self.user.booking_portal_client.support_number %>.<br/><br/>
                <Standard T&Cs>
              </div>
            </div>")
        end

        if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: 'not_payment_day_3').blank?
          Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: 'Lead', name: 'no_payment_day_3', subject: '<%= self.user.booking_portal_client.name %> | One step to go', content:
            "<div class = 'card'>
              <div class = 'card-body'>
                Dear <%= self.name %>,<br/>
                You are one step away from saving Rs. 50,000 and more on your home booking at <%= self.project.name %>.<br/><br/>
                In case of any further queries, please mail us at <%= self.user.booking_portal_client.support_email %> or call on <%= self.user.booking_portal_client.support_number %>.<br/><br/>
                <Standard T&Cs>
              </div>
            </div>")
        end

        if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: 'no_booking_day_4').blank?
          Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: 'Lead', name: 'no_booking_day_4', subject: '<%= self.user.booking_portal_client.name %> | Home loan requirement', content:
            "<div class = 'card'>
              <div class = 'card-body'>
                Dear <%= self.name %>,<br/>
                In case if you need a home loan, select loan preference in the KYC form and upload KYC so that our loan representative can help you.
                In case of any queries, please mail us at <%= self.user.booking_portal_client.support_email %> or call on <%= self.user.booking_portal_client.support_number %>.<br/><br/>
                <Standard T&Cs>
              </div>
            </div>")
        end

        if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: 'no_booking_day_5').blank?
          Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: 'Lead', name: 'no_booking_day_5', subject: '<%= self.booking_portal_client.name %> | Get additional discount of Rs.5,000 by completing your profile details', content:
            "<div class = 'card'>
              <div class = 'card-body'>
                Dear <%= self.name %>,<br/>
                Earn additional discounts at <%= self.project.name %> by completing your profile to help us know you better.
                In case of any queries, please mail us at <%= self.user.booking_portal_client.support_email %> or call on <%= self.user.booking_portal_client.support_number %>.<br/><br/>
                <Standard T&Cs>
              </div>
            </div>")
        end

        if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: 'no_booking_day_6').blank?
          Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: 'Lead', name: 'no_booking_day_6', subject: '<%= self.user.booking_portal_client.name %> | List of financial partners for home loan requirement', content:
            "<div class = 'card'>
              <div class = 'card-body'>
                Dear <%= self.name %>,<br/>
                Thank for showing your preference for the loan requirement for your dream home at <%= current_project.name %>. We have a host financial partners who are offering home loans at competitive rates. Please get in the touch with the financial partners from the list mentioned below.<br/><br/>
                <ol><li></li><li></li><li></li></ol>
                In case of any queries, please mail us at <%= self.user.booking_portal_client.support_email %> or call on <%= self.user.booking_portal_client.support_number %>.<br/><br/>
                We will start the allocation process on <date.> and will share all details in a follow up mail.<br/><br/>
                <Standard T&Cs>
              </div>
            </div>")
        end

        if ::Template::EmailTemplate.where(booking_portal_client_id: client_id, project_id: project_id, name: 'no_booking_day_7').blank?
          Template::EmailTemplate.create!(booking_portal_client_id: client_id, project_id: project_id, subject_class: 'Lead', name: 'no_booking_day_7', subject: '<%= self.user.booking_portal_client.name %> | Get additional discount of Rs.20,000 by making your friends your neighbour', content:
            "<div class = 'card'>
              <div class = 'card-body'>
                Dear <%= self.name %>,<br/>
                Earn additional discounts by referring your 3 friends at <%= self.project.name %>.
                In case of any queries, please mail us at <%= self.user.booking_portal_client.support_email %> or call on <%= self.user.booking_portal_client.support_number %>.<br/><br/>
                <Standard T&Cs>
              </div>
            </div>")
        end
      end
    end
  end
end
