class Crm::Api::Post < Crm::Api
  include Mongoid::Document

  def process_request
    puts "post"
  end
end
