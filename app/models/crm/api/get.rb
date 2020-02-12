class Crm::Api::Get < Crm::Api
  include Mongoid::Document

  def process_request
    puts "get"
  end
end
