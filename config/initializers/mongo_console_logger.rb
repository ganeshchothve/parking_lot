# This initializer adds a method, show_mongo, when running a rails console. When active, all
# mongo commands (mongo is mongoid's mongodb driver) will be logged inline in the console output.
# If called again, logging will be restored to normal (written to log files, not shown inline).
# Usage:
#     > show_mongo

if defined?(Rails::Console)
  def show_mongo
    if Mongo::Logger.logger == Rails.logger
      Mongo::Logger.logger = Logger.new($stdout)
      true
    else
      Mongo::Logger.logger = Rails.logger
      false
    end
  end
end
