#
# Whatsapp worker for communication
#
# @author Dnyaneshwar Burgute <dnyaneshwar.burgute@sell.do>
#
require 'net/http'
require 'rexml/document'
module Communication
  module Whatsapp
    class WhatsappWorker
      include Sidekiq::Worker

      def perform whatsapp_id
        whatsapp = ::Whatsapp.find whatsapp_id
        if %w[staging production].include?(Rails.env)
          resp = WhatsappNotifier::Base.send(whatsapp)
          # TODO : : uncomment if implemented Haptik
          # if whatsapp.vendor == 'WhatsappNotifier::Haptik'
          #   whatsapp.content = resp[:content]
          # end
          # TODO : : Handle all statuses
          whatsapp.sent_on = DateTime.now
          whatsapp.status = (resp[:status] == 'queued') ? 'sent' : resp[:status]
          whatsapp.message_sid = resp[:message_sid]
          whatsapp.api_version = resp[:api_version]
          whatsapp.save
        end
      end
    end
  end
end
