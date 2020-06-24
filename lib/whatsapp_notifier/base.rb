#
# Class WhatsappNotifier selects whatsapp vendor and sends the whatsapp message
#
# @author Dnyaneshwar Burgute <dnyaneshwar.burgute@sell.do>
#
module WhatsappNotifier
  class Base
    def self.send(whatsapp)
      return eval(whatsapp.vendor).new(whatsapp).send()
    end
  end
end
